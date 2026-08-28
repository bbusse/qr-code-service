'''
Encoding a qr-code to a png

© 2021 Björn Busse (see also: LICENSE)
bj.rn@baerlin.eu
'''

import hashlib
import logging
import os
import tempfile

import segno

DEFAULT_SIZE = 15
DEFAULT_MARGIN = 2


def scale_for(qr, target_px, margin):
    '''
    The scale that brings a symbol closest to target_px without exceeding it.

    A qr-code is a grid of modules and scale is the pixels each one occupies,
    so the pixel size follows from the amount of data: the same scale gives a
    much larger image for a long url than a short one. Callers laying out a
    view want a predictable size instead.
    '''
    modules = qr.symbol_size(scale=1, border=margin)[0]

    return max(1, int(target_px // modules))


class QREncodeError(RuntimeError):
    ''' Raised when a qr-code could not be produced '''


def filename(url, size=DEFAULT_SIZE, margin=DEFAULT_MARGIN):
    '''
    The name a given encoding is cached under. The url is hashed rather than
    used directly: it is attacker-influenced in the service, and a url is not
    a safe path component.
    '''
    fileid = hashlib.md5(url.encode(encoding='UTF-8')).hexdigest()
    return f"{fileid}_{size}_{margin}.png"


def encode_to_dir(url, directory, size=DEFAULT_SIZE, margin=DEFAULT_MARGIN,
                  target_px=None):
    '''
    Writes a qr-code png for url into directory and returns its path.
    An encoding already present is returned as it stands, the name covering
    every input that changes the image.
    '''
    if not url:
        raise QREncodeError("no url to encode")

    qr = segno.make(url, error="m")
    if target_px:
        size = scale_for(qr, target_px, margin)

    os.makedirs(directory, exist_ok=True)
    path = os.path.join(directory, filename(url, size, margin))

    if os.path.isfile(path) and os.path.getsize(path) > 0:
        logging.debug("qr: serving existing %s", path)
        return path

    # Written to a temporary name first and moved into place, so a reader
    # never sees a half-written png and a failed run leaves nothing behind
    fd, tmp = tempfile.mkstemp(dir=directory, suffix=".png")
    os.close(fd)
    try:
        # scale is the pixels per module, border the quiet zone in modules,
        # which is what qrencode called size and margin
        qr.save(tmp, kind="png", scale=size, border=margin)
        if os.path.getsize(tmp) == 0:
            raise QREncodeError("encoding produced an empty file")
        os.replace(tmp, path)
    except QREncodeError:
        if os.path.exists(tmp):
            os.remove(tmp)
        raise
    except (OSError, ValueError) as e:
        if os.path.exists(tmp):
            os.remove(tmp)
        raise QREncodeError(f"could not encode {url!r}: {e}") from e

    return path


def encode(url, size=DEFAULT_SIZE, margin=DEFAULT_MARGIN, directory=None,
           target_px=None):
    '''
    Writes a qr-code png for url and returns its path, defaulting to a
    directory of our own under the system temporary directory.
    '''
    if directory is None:
        directory = os.path.join(tempfile.gettempdir(), "qr-codes")

    return encode_to_dir(url, directory, size=size, margin=margin,
                         target_px=target_px)
