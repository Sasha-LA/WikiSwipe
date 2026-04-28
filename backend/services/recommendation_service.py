import math

def calculate_score(topic_preference: float, is_unseen: bool, days_since_published: int, repeat_count: int, genre_preference: float = 1.0) -> float:
    # Basic ranking formula based on the prompt instructions
    score = (topic_preference + genre_preference) / 2.0
    if is_unseen:
        score += 2.0
    
    # Recency bonus
    score += max(0.0, float((30 - days_since_published) * 0.05))
    
    # Repeat penalty
    score -= float(repeat_count) * 1.5
    
    return max(0.1, float(score))
