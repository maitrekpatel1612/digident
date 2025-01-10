import cv2
import numpy as np

def compress_frame(frame, quality=80):
    encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), quality]
    _, encoded = cv2.imencode('.jpg', frame, encode_param)
    return encoded