module nimir.systems.audiovideo;

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
import std.file;
import std.path;
import nimir.image;

static this()
{
    av_register_all();
    avdevice_register_all();
	//av_log_set_level(0);
}

static ~this()
{

}
/*
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

class VideoStream
{

    this()
    {
        frame = new NimirImage(); frame.loadFile(std.format.format("%s%s", thisExePath().dirName(), "/res/nimirui-logo-128x40.png"));
    }

    bool init(string source, uint fps, uint[2] dimensions)
    {
        format        = av_find_input_format("avfoundation");
	formatContext = avformat_alloc_context();

        av_dict_set(&options, "framerate", std.format.format("%d", fps).toStringz, 0);
        av_dict_set(&options, "video_size", std.format.format("%dx%d", dimensions[0], dimensions[1]).toStringz, 0);

        if (avformat_open_input(&formatContext, source.toStringz, format, &options) != 0) return false;
	if (avformat_find_stream_info(formatContext, &options) < 0) return false;
	av_dump_format(formatContext, 0, source.toStringz, 0);

        for (int i = 0; i < formatContext.nb_streams; i++)
    	{
		if (formatContext.streams[i].codec.codec_type == AVMediaType.AVMEDIA_TYPE_VIDEO)
    		{
			videoIndex = i;
    			break;
    		}
    	}

        if(videoIndex == -1) return false;

	codec = avcodec_find_decoder(formatContext.streams[videoIndex].codec.codec_id);
	codecContext = formatContext.streams[videoIndex].codec;

	codecContext.width = dimensions[0]; //or 1280x720
	codecContext.height = dimensions[1];
	codecContext.pix_fmt = AVPixelFormat.AV_PIX_FMT_UYVY422;

    	//warn: find a way to input uyvy422 as pixel format for camera.
	if(codec == null) return false;
	if(codecContext == null) return false;
	if(avcodec_open2(codecContext, codec, null) < 0) return false;

	codecContext.pix_fmt = AVPixelFormat.AV_PIX_FMT_UYVY422;

    	rawFrame = av_frame_alloc(); convertedFrame = av_frame_alloc();

	frameBytes = avpicture_get_size(AVPixelFormat.AV_PIX_FMT_RGB24, codecContext.width, codecContext.height);
    	frameBuffer = cast(ubyte*) av_malloc(frameBytes * ubyte.sizeof);
	avpicture_fill(cast(AVPicture*) convertedFrame, frameBuffer, AVPixelFormat.AV_PIX_FMT_RGB24, codecContext.width, codecContext.height);

        imageConversionContext = sws_getCachedContext(null, codecContext.width, codecContext.height, codecContext.pix_fmt, codecContext.width, codecContext.height, AVPixelFormat.AV_PIX_FMT_RGB24, SWS_BICUBIC, null, null, null);
	if (imageConversionContext == null) return false;

        return true;
    }

    bool update()
    {
        if(av_read_frame(formatContext, &cameraPacket)>=0)
		{
			if(cameraPacket.stream_index == videoIndex)
			{
			avcodec_decode_video2(codecContext, rawFrame, &isFrameFinished, &cameraPacket);

		        if(isFrameFinished)
				{
		            sws_scale(imageConversionContext, rawFrame.data.ptr, rawFrame.linesize.ptr, 0, codecContext.height, convertedFrame.data.ptr, convertedFrame.linesize.ptr);
					frame.loadData(convertedFrame.data[0], codecContext.width, codecContext.height, 3);
		        }
	    	}
            return true;
		}

        return false;
    }

    NimirImage frame;

    AVDictionary*    options;
    AVInputFormat*   format;
    AVFormatContext* formatContext;
    AVCodec*         codec;
    AVCodecContext*  codecContext;

    int              videoIndex;

    AVFrame*         rawFrame, convertedFrame;
    SwsContext*      imageConversionContext;

    ubyte*           frameBuffer;
    int              frameBytes;
    AVPacket         cameraPacket;
    int              isFrameFinished;
}
