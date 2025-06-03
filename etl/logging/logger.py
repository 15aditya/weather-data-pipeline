import logging
import os

def get_logger(name: str=__name__) -> logging.Logger:
    logger = logging.getLogger(name)

    if not logger.handlers:
        log_level = os.getenv("LOG_LEVEL", "INFO").upper()

        handler = logging.StreamHandler()
        formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
        handler.setFormatter(formatter)

        logger.setLevel(log_level)
        logger.addHandler(handler)

    return logger



