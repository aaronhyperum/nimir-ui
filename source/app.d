module nimir.app;

import derelict.imgui.imgui;
import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import std.stdio;
import std.conv;
import std.path;
import std.file: read, thisExePath;
import std.string: toStringz, fromStringz, format;

import nimir.image;
import system = nimir.systems;
import serial.device;

//NOTE: Video initialization is commented out because of faulty SWS handling; waiting for software update.
//TODO: Move this to nimir.system, report issue on Github.

import ffmpeg.libavdevice.avdevice;
import ffmpeg.libavcodec.avcodec;
import ffmpeg.libavformat.avformat;
import ffmpeg.libavfilter.avfilter;
import ffmpeg.libavutil.avutil;
import ffmpeg.libavutil.mem;
import ffmpeg.libavutil.pixfmt;
import ffmpeg.libswscale.swscale;

NimirImage nimirLogo;
NimirImage video;
string[] ports;

void main()
{
	system.init(1280, 720, "Nimir UI");

	av_register_all();
    avdevice_register_all();
	//av_log_set_level(0);

	AVDictionary*    options;
	AVInputFormat*   cameraFormat        = av_find_input_format("avfoundation");
	AVFormatContext* cameraFormatContext = avformat_alloc_context();
	AVCodec*         cameraCodec         = null;
	AVCodecContext*  cameraCodecContext  = null;
	int              cameraVideo         = 0;
	string           cameraSource    = /*"USB 2.0 PC Cam";*/"USB";
	AVFrame*         rawFrame = null, convertedFrame = null;
	SwsContext*      imageConversionContext ;
	ubyte*           frameBuffer;
	int              frameBytes;

	AVPacket         cameraPacket;
	int              isFrameFinished = 0;

	av_dict_set(&options, "video_size", "640x480", 0);
	av_dict_set(&options, "framerate", "30", 0);

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

	bool mainWindow = false;
	bool show_another_window = false;
	bool show_test_window = false;

	ImFont* fontOSB = ImFontAtlas_AddFontFromFileTTF(igGetIO().Fonts, toStringz(format("%s%s", thisExePath().dirName(), "/res/ubuntu/ubuntu.mono-bold.ttf")), 14.0f, null);

	nimirLogo = new NimirImage();
	nimirLogo.loadFile("/Users/Home/Documents/nimirui-logo-128x40.png");

	video = new NimirImage();
	video.loadFile("/Users/Home/Documents/nimirui-logo-128x40.png");




	// Main loop
	while (system.window.shouldRun)
	{
		auto io = igGetIO();
		system.update();

		//NOTE: Video handling is commented out because of faulty SWS handling; waiting for software update.
		//TODO: Fix video handling, report issue on Github.

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

		{
			igSetNextWindowPos(ImVec2(400,400), ImGuiSetCond_FirstUseEver);
			igBegin("test", &mainWindow, ImGuiWindowFlags_AlwaysAutoResize);

			static float f = 0.0f;
			igText("Hello, world!");
			igSliderFloat("float", &f, 0.0f, 1.0f);
			igColorEdit3("clear color", system.clearColor);
			if (igButton("Test Window")) show_test_window ^= 1;
			if (igButton("Another Window")) show_another_window ^= 1;
			igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / io.Framerate, io.Framerate);
			igImage( cast(void*)video.glTexture, ImVec2(video.w*1.5, video.h*1.5), ImVec2(0,0), ImVec2(1,1),  ImVec4(255,255,255,255), ImVec4(255,255,255,0));
			igEnd();
		}

		ImVec2 size, pos;
		showPanel();

		if (show_test_window)
		{
		    igSetNextWindowPos(ImVec2(650, 20), ImGuiSetCond_FirstUseEver);
		    igShowTestWindow(&show_test_window);

		}

		system.render();
	}
	igPopStyleVar(1);

	{// Application cleanup.
		system.quit();
		nimirLogo.deinit();
		video.deinit();
	}
}

bool shouldShowMainPanel = true;
bool shouldShowControlPanel = true;

int shouldUseManualOutput = 0;
char[64] luaOutput = "";
char[64] manualOutput = "";


enum varNum = 4;
enum var {XAxis, YAxis, YHat, Trigger}
const(char)*[varNum] variables = ["X Axis", "Y Axis", "Y Hat", "Trigger"];
int variableIndex = 0;

int[varNum] inputJoystick = [-1, -1, -1, -1];
bool[varNum] inputUsingAxis;
int[varNum] inputButton = [-1, -1, -1, -1];
int[varNum] inputAxis = [-1, -1, -1, -1];
float[varNum] inputValue;
int portSelector;
const(char)*[] portc;



void showPanel()
{
	shouldShowMainPanel = true;

	ImVec2 sizeMainPanel = ImVec2(280, 80);
	ImVec2 posMainPanel = ImVec2(10, 10);

    igSetNextWindowPos(posMainPanel);
    igBegin("mainPanel", &shouldShowMainPanel, ImGuiWindowFlags_AlwaysAutoResize|ImGuiWindowFlags_NoTitleBar|ImGuiWindowFlags_NoResize|ImGuiWindowFlags_NoMove);
	{
	// Logo and version.
	igImage( cast(void*)nimirLogo.glTexture, ImVec2(nimirLogo.w, nimirLogo.h), ImVec2(0,0), ImVec2(1,1),  ImVec4(255,255,255,255), ImVec4(255,255,255,0));
	igSameLine(); igText("\nVersion: Alpha 0.0.0");

	igSeparator();

	// Main controls row.
	if (igButton("Load Lua File")) igOpenPopup("Load Lua File");
	if (igBeginPopupModal("Load Lua File", null, ImGuiWindowFlags_AlwaysAutoResize))
    {
        igText("Type path to Lua file:\n\n");
        igSeparator();

        bool dont_ask_me_next_time = false;
        igCheckbox("Don't ask me next time", &dont_ask_me_next_time);

        if (igButton("OK", ImVec2(120,0))) { igCloseCurrentPopup(); }
        igSameLine();
        if (igButton("Cancel", ImVec2(120,0))) { igCloseCurrentPopup(); }
        igEndPopup();
    }
	igSameLine();
	if (igButton("Load Video Source")) igOpenPopup("Load Video Source");
	igSameLine();
	if (igButton(shouldShowControlPanel? "Hide Panel" : "Show Panel")) shouldShowControlPanel ^= 1;

	// Retrieve size of GUI panel.
	igGetWindowSize(&sizeMainPanel);

	if (shouldShowControlPanel)
	{
		//igSetNextWindowPos(ImVec2(posMainPanel.x , 2 * posMainPanel.y + sizeMainPanel.y));
		//igSetNextWindowSize(ImVec2(sizeMainPanel.x, system.window.h - (3 * posMainPanel.y + sizeMainPanel.y)));
	    //igBegin("controlPanel", &shouldShowControlPanel, ImGuiWindowFlags_NoTitleBar|ImGuiWindowFlags_NoResize|ImGuiWindowFlags_AlwaysAutoResize|ImGuiWindowFlags_NoMove);

		// Serial IO Manipulation
		ports = SerialPort.ports;
		portc = new const(char)*[ports.length];
		for (int i = 0; i < ports.length; i++) portc[i] = ports[i].toStringz;
		igCombo("Ports", &portSelector, portc.ptr, cast(int)ports.length);

		igText("Lua output:");
		igInputText("###luaOutput", luaOutput.ptr, 64, ImGuiInputTextFlags_ReadOnly);
		igSameLine(); igRadioButton("###shouldUseManualOutputFalse", &shouldUseManualOutput, 0);

		igText("Manual output:");
		igInputText("###manualOutput", manualOutput.ptr, 64, ImGuiInputTextFlags_CharsUppercase | ImGuiInputTextFlags_CharsNoBlank);
		igSameLine(); igRadioButton("###shouldManualOutputTrue", &shouldUseManualOutput, 1);
		igText("");

		igSeparator();

		// Lua Controls
		igText("Lua file: <none>");
		igText("");

		igSeparator();

		// Video Controls
		igText("Video source: <none>");
		igText("");

		igSeparator();

		// Input Controls
		const(char)*[GLFW_JOYSTICK_LAST] joysticks;
		int maxJoystick = GLFW_JOYSTICK_LAST;
		for (int i = 0; i < GLFW_JOYSTICK_LAST; i++)
		{
			if(glfwJoystickPresent(i)) joysticks[i] = glfwGetJoystickName(i);
			else {joysticks[i] = "";}
		}

		igCombo("Input Var", &variableIndex, variables.ptr, varNum);
		igSeparator();

		if (variableIndex != -1)
		{
			igCombo("Joystick", &inputJoystick[variableIndex], joysticks.ptr, GLFW_JOYSTICK_LAST);
			//inputJoystick[variableIndex] = joystickIndex;
			igCheckbox("Input is Axis?", &inputUsingAxis[variableIndex]);
			//writefln("%d%d", inputJoystick[variableIndex], inputJoystick[variableIndex] != -1? glfwJoystickPresent(inputJoystick[variableIndex]) : 0);
			if (inputJoystick[variableIndex] != -1? glfwJoystickPresent(inputJoystick[variableIndex]) == 1 : false)
			{
				int count;
				float* rawAxes;
				ubyte* rawButtons;

				if(inputUsingAxis[variableIndex])
				{
					rawAxes = glfwGetJoystickAxes(inputJoystick[variableIndex], &count);

					const(char)*[] axes = new const(char)*[count];
					for (int i = 0; i < count; i++) axes[i] = format("Axis %d: %f", i+1, rawAxes[i]).toStringz;

					igCombo("Axes", &inputAxis[variableIndex], axes.ptr, count);
				}
				else
				{
					rawButtons = glfwGetJoystickButtons(inputJoystick[variableIndex], &count);

					const(char)*[] buttons = new const(char)*[count];
					for (int i = 0; i < count; i++) buttons[i] = format("Button %d: %s", i+1, rawButtons[i]? "Pressed" : "Released").toStringz;

					igCombo("Button", &inputButton[variableIndex], buttons.ptr, count);
				}

				for(int i = 0; i < varNum; i++)
				{
					inputValue[i] = inputUsingAxis[i]? rawAxes[inputAxis[i]] : rawButtons[inputButton[i]];
				}
				writeln(inputValue);
			}
		}



			igText("");
			igSeparator();


		}
	}
	igEnd();
	}
//}

void showLuaFileModal()
{

}

void showVideoSourceModal()
{

}
