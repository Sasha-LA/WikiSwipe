from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import uuid

import models, schemas
from database import engine, get_db

from services import wikipedia_service, summary_service, recommendation_service

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="WikiSwipe MVP")

@app.post("/users", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = models.User(id=user.id or uuid.uuid4())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/onboarding")
def onboarding(req: schemas.OnboardingRequest, db: Session = Depends(get_db)):
    """Save user interests"""
    # 0. Ensure user exists
    user = db.query(models.User).filter(models.User.id == req.user_id).first()
    if not user:
        db.add(models.User(id=req.user_id))
        db.commit()
        
    # 1. Fetch or create interests
    for interest_name in req.interests:
        interest = db.query(models.Interest).filter(models.Interest.name == interest_name).first()
        if not interest:
            interest = models.Interest(name=interest_name)
            db.add(interest)
            db.commit()
            db.refresh(interest)
        
        # 2. Assign to user
        ui = db.query(models.UserInterest).filter_by(user_id=req.user_id, interest_id=interest.id).first()
        if not ui:
            ui = models.UserInterest(user_id=req.user_id, interest_id=interest.id)
            db.add(ui)
            
        # 3. Initialize preference score
        pref = db.query(models.UserTopicPreference).filter_by(user_id=req.user_id, interest_id=interest.id).first()
        if not pref:
            pref = models.UserTopicPreference(user_id=req.user_id, interest_id=interest.id, score=1.0)
            db.add(pref)
    
    db.commit()
    return {"status": "success"}

@app.get("/feed", response_model=List[schemas.Article])
def get_feed(user_id: uuid.UUID, db: Session = Depends(get_db)):
    """Fetch feed based on recommendation logic (placeholder implementation)"""
    # Simply return articles the user hasn't swiped on yet, for topics they are interested in
    # In a full implementation, this uses RecommendationEngine
    # Query all user interests
    user_prefs = db.query(models.UserTopicPreference).filter(models.UserTopicPreference.user_id == user_id).order_by(models.UserTopicPreference.score.desc()).all()
    if not user_prefs:
        return []
    
    interest_ids = [p.interest_id for p in user_prefs]
    interest_names = [db.query(models.Interest).filter(models.Interest.id == i_id).first().name for i_id in interest_ids]
    
    swiped_article_ids = [s.article_id for s in db.query(models.SwipeEvent).filter(models.SwipeEvent.user_id == user_id).all()]
    
    articles = db.query(models.Article).filter(
        models.Article.id.notin_(swiped_article_ids),
        models.Article.topics.overlap(interest_names)
    ).limit(50).all()

    # If the feed pool is critically low, trigger a background refresh for their topics!
    if len(articles) < 5:
        # We can trigger it sync for MVP so they instantly get new cards
        import asyncio
        for topic in interest_names[:3]: # top 3 topics
            try:
                titles = asyncio.run(wikipedia_service.search_articles(topic, limit=10))
                for title in titles:
                    existing = db.query(models.Article).filter(models.Article.title == title).first()
                    if existing: continue
                    wiki_data = asyncio.run(wikipedia_service.get_article_content_and_image(title))
                    if not wiki_data["content"]: continue
                    summary = asyncio.run(summary_service.generate_summary(wiki_data["content"]))
                    new_art = models.Article(title=title, summary=summary, wiki_url=wiki_data["url"], image_url=wiki_data["image_url"], topics=[topic])
                    db.add(new_art)
                    db.commit()
                    db.refresh(new_art)
                    if new_art.id not in swiped_article_ids:
                        articles.append(new_art)
            except Exception as e:
                print(f"Error auto-refreshing {topic}: {e}")
                
    if not articles:
        return []

    # Score articles
    scored_articles = []
    
    # Simple recency mock via checking db order/id (since created_at might be None during testing) or assume 0 for MVP
    for article in articles:
        # Find preference
        pref_score = 1.0 # default
        for topic in article.topics:
            if topic in interest_names:
                idx = interest_names.index(topic)
                pref_score = max(pref_score, user_prefs[idx].score)
        
        score = recommendation_service.calculate_score(
            topic_preference=pref_score,
            is_unseen=True, # since we filter out swiped_article_ids above
            days_since_published=1, # simplified
            repeat_count=0
        )
        scored_articles.append((score, article))
        
    scored_articles.sort(key=lambda x: x[0], reverse=True)
    return [a[1] for a in scored_articles[:10]]
    
    return articles

@app.post("/swipe")
def swipe(req: schemas.SwipeRequest, db: Session = Depends(get_db)):
    """Record swipe and update preferences"""
    # 1. Record swipe
    swipe_event = models.SwipeEvent(user_id=req.user_id, article_id=req.article_id, swiped_right=req.swiped_right)
    db.add(swipe_event)
    
    # 2. Update preferences
    article = db.query(models.Article).filter(models.Article.id == req.article_id).first()
    if article:
        weight = 0.1 if req.swiped_right else -0.05
        for topic in article.topics:
            interest = db.query(models.Interest).filter(models.Interest.name == topic).first()
            if interest:
                pref = db.query(models.UserTopicPreference).filter_by(user_id=req.user_id, interest_id=interest.id).first()
                if pref:
                    pref.score += weight
                    # keep score positive
                    pref.score = max(0.1, pref.score)
                else:
                    pref = models.UserTopicPreference(user_id=req.user_id, interest_id=interest.id, score=1.0 + weight)
                    db.add(pref)
                    
    db.commit()
    return {"status": "success"}

@app.post("/refresh")
async def refresh_articles(req: schemas.RefreshRequest, db: Session = Depends(get_db)):
    """Pull new articles from Wikipedia"""
    if req.topics:
        topics = req.topics
    else:
        prefs = db.query(models.UserTopicPreference).filter_by(user_id=req.user_id).order_by(models.UserTopicPreference.score.desc()).limit(3).all()
        topics = [db.query(models.Interest).get(p.interest_id).name for p in prefs] if prefs else ["History", "Science", "Technology"]
            
    for topic in topics:
        titles = await wikipedia_service.search_articles(topic, limit=10)
        for title in titles:
            existing = db.query(models.Article).filter(models.Article.title == title).first()
            if existing:
                continue
                
            wiki_data = await wikipedia_service.get_article_content_and_image(title)
            if not wiki_data["content"]:
                continue
                
            summary = await summary_service.generate_summary(wiki_data["content"])
            
            article = models.Article(
                title=title,
                summary=summary,
                wiki_url=wiki_data["url"],
                image_url=wiki_data["image_url"],
                topics=[topic]
            )
            db.add(article)
            db.commit()
            
    return {"status": "success", "topics_refreshed": topics}

@app.get("/")
def read_root():
    return {"Hello": "WikiSwipe API"}
