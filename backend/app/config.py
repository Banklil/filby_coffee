from pydantic_settings import BaseSettings
from typing import List
import json


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://filby:filby123@localhost:5432/filby_admin"
    SECRET_KEY: str = "dev-secret-key-change-in-production-must-be-32-chars-min"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    CORS_ORIGINS: str = '["http://localhost:5173","http://localhost:80","http://localhost:3000"]'
    FRONTEND_URL: str = ""  # Set to https://your-frontend.railway.app in production
    UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE: int = 5 * 1024 * 1024
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    FROM_EMAIL: str = "noreply@filby.la"
    ENVIRONMENT: str = "development"

    @property
    def cors_origins_list(self) -> List[str]:
        try:
            origins = json.loads(self.CORS_ORIGINS)
        except (json.JSONDecodeError, ValueError):
            origins = [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]
        if self.FRONTEND_URL and self.FRONTEND_URL not in origins:
            origins.append(self.FRONTEND_URL)
        return origins

    class Config:
        env_file = ".env"


settings = Settings()
