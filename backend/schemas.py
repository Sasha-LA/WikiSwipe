from pydantic import BaseModel, HttpUrl, UUID4
from typing import List, Optional
from datetime import datetime, date

class UserCreate(BaseModel):
    id: Optional[UUID4] = None

class User(BaseModel):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class InterestBase(BaseModel):
    name: str

class InterestCreate(InterestBase):
    pass

class Interest(InterestBase):
    id: int

    class Config:
        from_attributes = True

class OnboardingRequest(BaseModel):
    user_id: UUID4
    interests: List[str]

class ArticleBase(BaseModel):
    title: str
    summary: Optional[str] = None
    wiki_url: HttpUrl
    image_url: Optional[HttpUrl] = None
    topics: List[str] = []
    genres: Optional[List[str]] = []

class Article(ArticleBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class SwipeRequest(BaseModel):
    user_id: UUID4
    article_id: int
    swiped_right: bool

class RefreshRequest(BaseModel):
    user_id: UUID4
    topics: Optional[List[str]] = None
