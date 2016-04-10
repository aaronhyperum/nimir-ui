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
import nimir.image;

/*static this()
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

final abstract class av
{   static:
    AVDictionary*    options;
    AVInputFormat*   cameraFormat;
    AVFormatContext* cameraFormatContext;
    AVCodec*         cameraCodec         = null;
    AVCodecContext*  cameraCodecContext  = null;
    int              cameraVideo         = 0;
    string           cameraSource    = /*"USB 2.0 PC Cam";*/"Face";
    AVFrame*         rawFrame = null, convertedFrame = null;
    SwsContext*      imageConversionContext ;
    ubyte*           frameBuffer;
    int              frameBytes;

    AVPacket         cameraPacket;
    int              isFrameFinished = 0;

    void init()
    {
        av_register_all();
        avdevice_register_all();
    	//av_log_set_level(0);

    	cameraFormat        = av_find_input_format("avfoundation");
    	cameraFormatContext = avformat_alloc_context();

    	av_dict_set(&options, "video_size", "640x480", 0);
    	av_dict_set(&options, "framerate", "25", 0);

    	if (avformat_open_input(&cameraFormatContext, cameraSource.toStringz, cameraFormat, &options) != 0) return;
    	if (avformat_find_stream_info(cameraFormatContext, &options) < 0) return;
    	av_dump_format(cameraFormatContext, 0, cameraSource.toStringz, 0);

    	for (int i = 0; i < cameraFormatContext.nb_streams; i++)
    	{
    		if (cameraFormatContext.streams[i].codec.codec_type == AVMediaType.AVMEDIA_TYPE_VIDEO)
    		{
    			cameraVideo = i;
    			break;
    		}
    	}

    	if(cameraVideo == -1) return;

    	cameraCodec = avcodec_find_decoder(cameraFormatContext.streams[cameraVideo].codec.codec_id);
    	cameraCodecContext = cameraFormatContext.streams[cameraVideo].codec;

    	cameraCodecContext.width = 640; //or 1280x720
    	cameraCodecContext.height = 480;
    	cameraCodecContext.pix_fmt = AVPixelFormat.AV_PIX_FMT_UYVY422;

    	//warn: find a way to input uyvy422 as pixel format for camera.
    	if(cameraCodec == null) return;
    	if(cameraCodecContext == null) return;
    	if(avcodec_open2(cameraCodecContext, cameraCodec, null) < 0) return;

    	cameraCodecContext.pix_fmt = AVPixelFormat.AV_PIX_FMT_UYVY422;

    	rawFrame = av_frame_alloc(); convertedFrame = av_frame_alloc();

    	frameBytes = avpicture_get_size(AVPixelFormat.AV_PIX_FMT_RGB24, cameraCodecContext.width, cameraCodecContext.height);
    	frameBuffer = cast(ubyte*) av_malloc(frameBytes * ubyte.sizeof);
    	avpicture_fill(cast(AVPicture*) convertedFrame, frameBuffer, AVPixelFormat.AV_PIX_FMT_RGB24, cameraCodecContext.width, cameraCodecContext.height);

    	imageConversionContext = sws_getCachedContext(null, cameraCodecContext.width, cameraCodecContext.height, cameraCodecContext.pix_fmt, cameraCodecContext.width, cameraCodecContext.height, AVPixelFormat.AV_PIX_FMT_RGB24, SWS_BICUBIC, null, null, null);
    	if (imageConversionContext == null) return;
    }
    void readFrame(ref NimirImage video)
    {
        if(av_read_frame(cameraFormatContext, &cameraPacket)>=0)
		{
			if(cameraPacket.stream_index == cameraVideo)
			{
	        	avcodec_decode_video2(cameraCodecContext, rawFrame, &isFrameFinished, &cameraPacket);

		        if(isFrameFinished)
				{
					//if(rawFrame.data.ptr == null || rawFrame.linesize.ptr == null || convertedFrame.data.ptr == null || convertedFrame.linesize.ptr == null) return;
		            sws_scale(imageConversionContext, rawFrame.data.ptr, rawFrame.linesize.ptr, 0, cameraCodecContext.height, convertedFrame.data.ptr, convertedFrame.linesize.ptr);
					video.loadData(convertedFrame.data[0], cameraCodecContext.width, cameraCodecContext.height, 3);
		        }
	    	}
		}
    }
}
