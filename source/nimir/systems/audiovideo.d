/*module nimir.systems.audiovideo;

import ffmpeg.libavdevice.avdevice;
import ffmpeg.libavcodec.avcodec;
import ffmpeg.libavformat.avformat;
import ffmpeg.libavfilter.avfilter;
import ffmpeg.libavutil.avutil;
import ffmpeg.libavutil.mem;
import ffmpeg.libavutil.pixfmt;
import ffmpeg.libswscale.swscale;

import std.string;
import std.format;

static this()
{
    av_register_all();
    avdevice_register_all();
	//av_log_set_level(0);
}

static ~this()
{

}

class Camera
{
    this (uint[2] dimensions, uint fps)
    {
        size = dimensions;
        framerate = fps;
    }
    @property void framerate(uint fps)
    {
        av_dict_set(&options, "framerate", format("%d", fps).toStringz, 0);
    }

    @property void size(uint[2] dimensions)
    {
        av_dict_set(&options, "video_size", format("%dx%d", uint[0], uint[1]).toStringz, 0);
    }

    AVDictionary*    options;
	AVInputFormat*   cameraFormat;
	AVFormatContext* cameraFormatContext;
	AVCodec*         cameraCodec;
	AVCodecContext*  cameraCodecContext;
	int              cameraVideo;
	string           cameraSource;
	AVFrame*         rawFrame, convertedFrame;
	SwsContext*      imageConversionContext;
	ubyte*           frameBuffer;
	int              frameBytes;
    AVPacket         cameraPacket;
	int              frameFinished = 0;
    int w, h;
}*/
