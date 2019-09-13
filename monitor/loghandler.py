import logging
from azure_storage_logging.handlers import QueueStorageHandler

logger = logging.getHandler("sapmonitortest")
handler = (account_name=None, account_key=None, protocol='https', queue='logs', message_ttl=None, visibility_timeout=None, base64_encoding=False, is_emulated=False)
logger.addHandler(handler)
logger.info("seriously?")
logger.warning("ya ya")
logger.debug("forget it")
