#!/usr/bin/env python3

import argparse
import logging

from dateutil.parser import parse

logger = logging.getLogger()
log_level = logging.INFO

logging.basicConfig(
    format='[{levelname}] {asctime}|{module}:{lineno} - {message}',
    level=log_level,
    datefmt='%y-%m-%d %H:%M:%S',
    style='{'
)

parser = argparse.ArgumentParser()
parser.add_argument('modified_ts')
parser.add_argument('installed_ts')
args = parser.parse_args()

logger.debug(args)
modified_timestamp = args.modified_ts.strip(' EST ')
installed_timestamp = args.installed_ts.strip(' EST ')
try:
    modified_timestamp = parse(modified_timestamp)
    installed_timestamp = parse(installed_timestamp)
except ValueError:
    logger.exception('Issues parsing dates')
    logger.info(f'modified_timestamp: {args.modified_ts} | {modified_timestamp}')
    logger.info(f'installed_timestamp: {args.installed_ts} | {installed_timestamp}')

result = modified_timestamp > installed_timestamp
if result:
    print(result)
