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


def pad_to(source, target_px, light=None):
    '''
    Centres a rendered symbol in a target_px square of quiet zone.

    Scale is whole pixels per module, so modules * scale lands wherever the
    module count puts it and a longer url comes out a different size from a
    short one. Padding to the square afterwards makes every code identical,
    and a wider quiet zone is what the spec asks for anyway.
    '''
    from PIL import Image

    with Image.open(source) as img:
        symbol = img.convert("RGB")
        if symbol.width >= target_px:
            return symbol.copy()

        canvas = Image.new("RGB", (target_px, target_px),
                           light or (255, 255, 255))
        canvas.paste(symbol, ((target_px - symbol.width) // 2,
                              (target_px - symbol.height) // 2))

        return canvas


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


MAX_CACHED = 512

def prune(directory, keep=None):
    '''
    Bounds the cache directory: on an appliance the temporary directory is
    tmpfs, so codes for every url a feed ever surfaced would otherwise sit in
    memory for the uptime of the device. Oldest first, and only pngs, so a
    concurrent encode's tempfile is never swept.
    '''
    if keep is None:
        keep = MAX_CACHED
    try:
        entries = [e for e in os.scandir(directory)
                   if e.name.endswith(".png")]
    except OSError:
        return
    if len(entries) <= keep:
        return
    entries.sort(key=lambda e: e.stat().st_mtime)
    for entry in entries[:len(entries) - keep]:
        try:
            os.remove(entry.path)
        except OSError:
            pass


def colour_key(value):
    '''
    A colour as a filename component: colours arrive as css names or as hex
    with a leading #, which is not a character to put in a path
    '''
    return str(value).lstrip("#") if value else "d"


def encode_to_dir(url, directory, size=DEFAULT_SIZE, margin=DEFAULT_MARGIN,
                  target_px=None, dark=None, light=None):
    '''
    Writes a qr-code png for url into directory and returns its path.
    An encoding already present is returned as it stands, the name covering
    every input that changes the image.
    '''
    if not url:
        raise QREncodeError("no url to encode")

    os.makedirs(directory, exist_ok=True)
    key = f"t{target_px}" if target_px else size
    if dark or light:
        key = f"{key}_{colour_key(dark)}_{colour_key(light)}"
    path = os.path.join(directory, filename(url, key, margin))

    if os.path.isfile(path) and os.path.getsize(path) > 0:
        logging.debug("qr: serving existing %s", path)
        return path

    qr = segno.make(url, error="m")
    if target_px:
        size = scale_for(qr, target_px, margin)

    # Written to a temporary name first and moved into place, so a reader
    # never sees a half-written png and a failed run leaves nothing behind
    fd, tmp = tempfile.mkstemp(dir=directory, suffix=".png")
    os.close(fd)
    try:
        # scale is the pixels per module, border the quiet zone in modules,
        # which is what qrencode called size and margin
        qr.save(tmp, kind="png", scale=size, border=margin,
                dark=dark or "#000", light=light or "#fff")
        if os.path.getsize(tmp) == 0:
            raise QREncodeError("encoding produced an empty file")
        if target_px:
            pad_to(tmp, target_px, light).save(tmp, format="PNG")
        os.replace(tmp, path)
        prune(directory)
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
           target_px=None, dark=None, light=None):
    '''
    Writes a qr-code png for url and returns its path, defaulting to a
    directory of our own under the system temporary directory.
    '''
    if directory is None:
        directory = os.path.join(tempfile.gettempdir(), "qr-codes")

    return encode_to_dir(url, directory, size=size, margin=margin,
                         target_px=target_px, dark=dark, light=light)
