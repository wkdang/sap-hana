import logging
import sys
from azure_storage_logging.handlers import QueueStorageHandler

logger = logging.getLogger("sapmonitortest")
handler = QueueStorageHandler(account_name=sys.argv[1], account_key=sys.argv[2], protocol='https', queue='logs', message_ttl=None, visibility_timeout=None, base64_encoding=False, is_emulated=False)
logger.addHandler(handler)
logger.info("seriously?")
logger.warning("ya ya")
logger.debug("forget it")
