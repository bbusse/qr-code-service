'''
Encoding a qr-code to a png, by way of the qrencode binary

© 2021 Björn Busse (see also: LICENSE)
bj.rn@baerlin.eu
'''

import hashlib
import logging
import os
import shutil
import subprocess
import tempfile

DEFAULT_SIZE = 15
DEFAULT_MARGIN = 2


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


def encode_to_dir(url, directory, size=DEFAULT_SIZE, margin=DEFAULT_MARGIN):
    '''
    Writes a qr-code png for url into directory and returns its path.
    An encoding already present is returned as it stands, the name covering
    every input that changes the image.
    '''
    if not url:
        raise QREncodeError("no url to encode")

    os.makedirs(directory, exist_ok=True)
    path = os.path.join(directory, filename(url, size, margin))

    if os.path.isfile(path) and os.path.getsize(path) > 0:
        logging.debug("qr: serving existing %s", path)
        return path

    if not shutil.which("qrencode"):
        raise QREncodeError("qrencode is not installed")

    # Written to a temporary name first and moved into place, so a reader
    # never sees a half-written png and a failed run leaves nothing behind
    fd, tmp = tempfile.mkstemp(dir=directory, suffix=".png")
    os.close(fd)
    try:
        result = subprocess.run(["qrencode",
                                 "-m", str(margin),
                                 "--size", str(size),
                                 "-o", tmp,
                                 url],
                                capture_output=True,
                                check=False)
        if result.returncode != 0 or os.path.getsize(tmp) == 0:
            raise QREncodeError(
                f"qrencode failed: {result.stderr.decode(errors='replace').strip()}")
        os.replace(tmp, path)
    except QREncodeError:
        if os.path.exists(tmp):
            os.remove(tmp)
        raise
    except OSError as e:
        if os.path.exists(tmp):
            os.remove(tmp)
        raise QREncodeError(f"could not write {path}: {e}") from e

    return path


def encode(url, size=DEFAULT_SIZE, margin=DEFAULT_MARGIN, directory=None):
    '''
    Writes a qr-code png for url and returns its path, defaulting to a
    directory of our own under the system temporary directory.
    '''
    if directory is None:
        directory = os.path.join(tempfile.gettempdir(), "qr-codes")

    return encode_to_dir(url, directory, size=size, margin=margin)
