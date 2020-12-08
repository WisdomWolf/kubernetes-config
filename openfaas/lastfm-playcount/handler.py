import logging
from urllib.parse import urlparse, unquote_plus

import requests

STANDARD_LOG_FORMAT = '[{levelname}] {asctime}|{module}:{lineno} - {message}'
DATE_FORMAT = '%Y-%m-%dT%H:%M:%S'

logger = logging.getLogger(__name__)

logging.basicConfig(
    format=STANDARD_LOG_FORMAT,
    level=logging.INFO,
    datefmt='%m-%d-%y %H:%M:%S',
    style='{'
)
logger.setLevel(logging.DEBUG)


def handle(event, context):
    logger.debug('event: %s', vars(event))
    logger.debug('context: %s', vars(context))
    try:
        username = event.query['username']
        logger.debug('username: %s', username)
    except KeyError:
        return {
            "statusCode": 400,
            "body": {
                "error": "username is required"
            }
        }

    title = event.query.get('title')
    logger.debug('title: %s', title)
    artist = event.query.get('artist')
    logger.debug('artist: %s', artist)
    track_url = event.query.get('track_url')
    logger.debug('track_url: %s', track_url)
    if not track_url and not (title or artist):
        return {
            "statusCode": 400,
            "body": {
                "error": "either a track_url or a title and artist are required"
            }
        }

    if track_url:
        artist, title = get_artist_title_from_url(track_url)

    playcount = get_playcount(username, title, artist)

    result = {
        "statusCode": 200,
        "body": {
            "results": {
                "username": username,
                "playcount": playcount
            }
        }
    }

    logger.debug('result: %s', result)
    return result


def get_api_key():
    with open('/var/openfaas/secrets/lastfm-api-key') as f:
        api_key = f.read()
    logger.debug('api key: %s', api_key)
    return api_key


def get_artist_title_from_url(track_url):
    path = urlparse(track_url).path
    artist, title = path.strip('/music/').split('/_/')
    artist = unquote_plus(artist)
    title = unquote_plus(title)
    return artist, title


def get_playcount(username, title, artist):
    url = f'https://ws.audioscrobbler.com/2.0/?method=track.getInfo'
    params = {
        'api_key': get_api_key(),
        'track': title,
        'artist': artist,
        'username': username,
        'format': 'json'
    }
    logger.debug('Attempting to send get request %s with params: %s',
                 url, params)
    result = requests.get(url, params=params)
    logger.debug('Request result: %s', result)
    if result and result.ok:
        playcount = result.json().get(
            'track', {}
        ).get(
            'userplaycount', 'ERROR'
        )
        logger.debug('returning playcount: %s', result)
        return playcount
    else:
        return result


