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
import nimir.systems.graphics;
import system = nimir.systems;
import serial.device;

import nimir.systems.audiovideo;

//NOTE: Video initialization is commented out because of faulty SWS handling; waiting for software update.
//TODO: Move this to nimir.system, report issue on Github.

import nimir.systems.audiovideo;

NimirImage nimirLogo;
NimirImage video;
VideoStream videostream;
VideoStream usb1, usb2, usb3;


string[] ports;

void main()
{
	system.init(1280, 720, "Nimir UI");

	bool mainWindow = false;
	bool show_another_window = false;
	bool show_test_window = false;
	ImFont* fontOSB = ImFontAtlas_AddFontFromFileTTF(igGetIO().Fonts, toStringz(format("%s%s", thisExePath().dirName(), "/res/ubuntu/ubuntu.mono-bold.ttf")), 14.0f, null);
	nimirLogo = new NimirImage(); nimirLogo.loadFile(format("%s%s", thisExePath().dirName(), "/res/nimirui-logo-128x40.png"));
	video = new NimirImage(); video.loadFile(format("%s%s", thisExePath().dirName(), "/res/nimirui-logo-128x40.png"));
	//videostream = new VideoStream();
	usb1 = new VideoStream();
	//usb2 = new VideoStream();
	//usb3 = new VideoStream();

	//videostream.init("Face", 25, [640, 480]);

	if (!usb1.init("USB", 25, [640, 480])) return;
	//usb2.init("USB 2.0 PC Cam #2", 30, [640, 480]);
	//usb3.init("USB 2.0 PC Cam #3", 30, [640, 480]);

	while (system.window.shouldRun)
	{
		auto io = igGetIO();
		system.update();
		//videostream.update();
		usb1.update();
		//usb2.update();
		//usb3.update();

		{
			igSetNextWindowPos(ImVec2(400,400), ImGuiSetCond_FirstUseEver);
			igBegin("Camera Feed", &mainWindow, ImGuiWindowFlags_AlwaysAutoResize);

			igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / io.Framerate, io.Framerate);
			igImage( cast(void*)usb1.frame.glTexture, ImVec2(usb1.frame.w*1.5, usb1.frame.h*1.5), ImVec2(0,0), ImVec2(1,1),  ImVec4(255,255,255,255), ImVec4(255,255,255,0));
			//igImage( cast(void*)usb2.frame.glTexture, ImVec2(usb2.frame.w*1.5, usb2.frame.h*1.5), ImVec2(0,0), ImVec2(1,1),  ImVec4(255,255,255,255), ImVec4(255,255,255,0));
			//igImage( cast(void*)usb3.frame.glTexture, ImVec2(usb3.frame.w*1.5, usb3.frame.h*1.5), ImVec2(0,0), ImVec2(1,1),  ImVec4(255,255,255,255), ImVec4(255,255,255,0));
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
	igSeparator();

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

		//igCombo("Input Var", &variableIndex, variables.ptr, varNum);
		//igSeparator();

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

			}
		}
		igText("");
		igSeparator();
	}
	igEnd();
}
void showLuaFileModal()
{

}

void showVideoSourceModal()
{

}
