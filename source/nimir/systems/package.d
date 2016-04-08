module nimir.systems;

import nimir.systems.window;
import nimir.systems.gui;

import derelict.imgui.imgui;
import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;
import std.string;
import std.stdio;
import imageformats;

bool initialized = false;

//GLFWwindow*  window;
Window window;

double       time = 0.0f;
bool[3]      mousePressed;
float        mouseWheel = 0.0f;
float[3]     clearColor = [0.9f, 0.9f, 0.9f];

/+
    SYSTEMS INTERFACE
+/

bool init(int w, int h, string title)
{
    if (!initialized)
    {
        initialized = true;

        window = new Window(w, h, title);

        window.onMouse = (handle, button, action, mods)
        {
            if (action != GLFW_RELEASE && button >= 0 && button < 3) mousePressed[button] = true;
        };
        window.onScroll = (handle, xoffset, yoffset)
        {
            mouseWheel += cast(float)yoffset;
        };
        window.onKey = (handle, key, scancode, action, mods)
        {
            gui.io.KeysDown[key] = action == GLFW_PRESS? true : false;
            gui.io.KeyCtrl = (mods & GLFW_MOD_CONTROL) != 0;
            gui.io.KeyShift = (mods & GLFW_MOD_SHIFT) != 0;
            gui.io.KeyAlt = (mods & GLFW_MOD_ALT) != 0;
        };
        window.onCharacter = (window, codepoint)
        {
            if (codepoint > 0 && codepoint < 0x10000) ImGuiIO_AddInputCharacter(cast(ushort)codepoint);
        };

        gui.io.KeyMap[ImGuiKey_Tab] = GLFW_KEY_TAB;                 // Keyboard mapping. ImGui will use those indices to peek into the gui.io.KeyDown[] array.
        gui.io.KeyMap[ImGuiKey_LeftArrow] = GLFW_KEY_LEFT;
        gui.io.KeyMap[ImGuiKey_RightArrow] = GLFW_KEY_RIGHT;
        gui.io.KeyMap[ImGuiKey_UpArrow] = GLFW_KEY_UP;
        gui.io.KeyMap[ImGuiKey_DownArrow] = GLFW_KEY_DOWN;
        gui.io.KeyMap[ImGuiKey_Home] = GLFW_KEY_HOME;
        gui.io.KeyMap[ImGuiKey_End] = GLFW_KEY_END;
        gui.io.KeyMap[ImGuiKey_Delete] = GLFW_KEY_DELETE;
        gui.io.KeyMap[ImGuiKey_Backspace] = GLFW_KEY_BACKSPACE;
        gui.io.KeyMap[ImGuiKey_Enter] = GLFW_KEY_ENTER;
        gui.io.KeyMap[ImGuiKey_Escape] = GLFW_KEY_ESCAPE;
        gui.io.KeyMap[ImGuiKey_A] = GLFW_KEY_A;
        gui.io.KeyMap[ImGuiKey_C] = GLFW_KEY_C;
        gui.io.KeyMap[ImGuiKey_V] = GLFW_KEY_V;
        gui.io.KeyMap[ImGuiKey_X] = GLFW_KEY_X;
        gui.io.KeyMap[ImGuiKey_Y] = GLFW_KEY_Y;
        gui.io.KeyMap[ImGuiKey_Z] = GLFW_KEY_Z;

        gui.io.SetClipboardTextFn = (ct){window.clipboardText = ct;};
        gui.io.GetClipboardTextFn = (){return window.clipboardText;};

        version (Win32) gui.io.ImeWindowHandle = window.win32;
        cast() gui.io.IniFilename = null;

        gui.style.Colors[ImGuiCol_Text]                  = ImVec4(1.00f, 1.00f, 1.00f, 1.00f);
        gui.style.Colors[ImGuiCol_TextDisabled]          = ImVec4(0.60f, 0.60f, 0.60f, 1.00f);

        gui.style.Colors[ImGuiCol_WindowBg]              = ImVec4(0.20f, 0.20f, 0.20f, 1.00f);
        gui.style.Colors[ImGuiCol_ChildWindowBg]         = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
        gui.style.Colors[ImGuiCol_Border]                = ImVec4(0.60f, 0.60f, 0.60f, 0.80f);
        gui.style.Colors[ImGuiCol_BorderShadow]          = ImVec4(1.00f, 1.00f, 1.00f, 0.00f);
        gui.style.Colors[ImGuiCol_FrameBg]               = ImVec4(0.70f, 0.70f, 0.70f, 0.40f);
        gui.style.Colors[ImGuiCol_FrameBgHovered]        = ImVec4(0.50f, 0.50f, 0.50f, 0.40f);
        gui.style.Colors[ImGuiCol_FrameBgActive]         = ImVec4(1.00f, 0.60f, 0.30f, 0.40f);
        gui.style.Colors[ImGuiCol_TitleBg]               = ImVec4(0.40f, 0.40f, 0.40f, 0.25f);
        gui.style.Colors[ImGuiCol_TitleBgCollapsed]      = ImVec4(0.40f, 0.40f, 0.40f, 0.25f);
        gui.style.Colors[ImGuiCol_TitleBgActive]         = ImVec4(0.40f, 0.40f, 0.40f, 0.25f);
        gui.style.Colors[ImGuiCol_MenuBarBg]             = ImVec4(0.40f, 0.40f, 0.40f, 0.25f);
        gui.style.Colors[ImGuiCol_ScrollbarBg]           = ImVec4(0.98f, 0.98f, 0.98f, 0.53f);
        gui.style.Colors[ImGuiCol_ScrollbarGrab]         = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        gui.style.Colors[ImGuiCol_ScrollbarGrabHovered]  = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        gui.style.Colors[ImGuiCol_ScrollbarGrabActive]   = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);

        gui.style.Colors[ImGuiCol_ComboBg]               = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        gui.style.Colors[ImGuiCol_CheckMark]             = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        gui.style.Colors[ImGuiCol_SliderGrab]            = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        gui.style.Colors[ImGuiCol_SliderGrabActive]      = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        gui.style.Colors[ImGuiCol_Button]                = ImVec4(0.20f, 0.20f, 0.20f, 0.60f);
        gui.style.Colors[ImGuiCol_ButtonHovered]         = ImVec4(0.30f, 0.30f, 0.30f, 0.60f);
        gui.style.Colors[ImGuiCol_ButtonActive]          = ImVec4(1.00f, 0.60f, 0.30f, 0.60f);
        gui.style.Colors[ImGuiCol_Header]                = ImVec4(0.20f, 0.20f, 0.20f, 0.60f);
        gui.style.Colors[ImGuiCol_HeaderHovered]         = ImVec4(0.30f, 0.30f, 0.30f, 0.60f);
        gui.style.Colors[ImGuiCol_HeaderActive]          = ImVec4(1.00f, 0.60f, 0.30f, 0.60f);
        gui.style.Colors[ImGuiCol_Column]                = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        gui.style.Colors[ImGuiCol_ColumnHovered]         = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        gui.style.Colors[ImGuiCol_ColumnActive]          = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);

        gui.style.Colors[ImGuiCol_ResizeGrip]            = ImVec4(1.00f, 1.00f, 1.00f, 0.00f);
        gui.style.Colors[ImGuiCol_ResizeGripHovered]     = ImVec4(0.26f, 0.59f, 0.98f, 0.00f);
        gui.style.Colors[ImGuiCol_ResizeGripActive]      = ImVec4(0.26f, 0.59f, 0.98f, 0.00f);
        gui.style.Colors[ImGuiCol_CloseButton]           = ImVec4(0.59f, 0.59f, 0.59f, 0.00f);
        gui.style.Colors[ImGuiCol_CloseButtonHovered]    = ImVec4(0.98f, 0.39f, 0.36f, 1.00f);
        gui.style.Colors[ImGuiCol_CloseButtonActive]     = ImVec4(0.98f, 0.39f, 0.36f, 1.00f);

        gui.style.Colors[ImGuiCol_PlotLines]             = ImVec4(0.39f, 0.39f, 0.39f, 1.00f);
        gui.style.Colors[ImGuiCol_PlotLinesHovered]      = ImVec4(1.00f, 0.43f, 0.35f, 1.00f);
        gui.style.Colors[ImGuiCol_PlotHistogram]         = ImVec4(0.90f, 0.70f, 0.00f, 1.00f);
        gui.style.Colors[ImGuiCol_PlotHistogramHovered]  = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);

        gui.style.Colors[ImGuiCol_TextSelectedBg]        = ImVec4(0.26f, 0.59f, 0.98f, 1.00f);
        gui.style.Colors[ImGuiCol_TooltipBg]             = ImVec4(1.00f, 1.00f, 1.00f, 0.40f);
        gui.style.Colors[ImGuiCol_ModalWindowDarkening]  = ImVec4(0.20f, 0.20f, 0.20f, 0.35f);

        gui.style.WindowTitleAlign = ImGuiAlign_Center;

        igPushStyleVar(ImGuiStyleVar_WindowRounding, 4.0f);
    	igPushStyleVar(ImGuiStyleVar_FrameRounding, 2.0f);
    }
    return initialized;
}

void quit()
{
    if (gui.vaoHandle) glDeleteVertexArrays(1, &gui.vaoHandle);
    if (gui.vboHandle) glDeleteBuffers(1, &gui.vboHandle);
    if (gui.elementsHandle) glDeleteBuffers(1, &gui.elementsHandle);
    gui.vaoHandle = 0;
    gui.vboHandle = 0;
    gui.elementsHandle = 0;

    glDetachShader(gui.shaderHandle, gui.vertHandle);
    glDeleteShader(gui.vertHandle);
    gui.vertHandle = 0;

    glDetachShader(gui.shaderHandle, gui.fragHandle);
    glDeleteShader(gui.fragHandle);
    gui.fragHandle = 0;

    glDeleteProgram(gui.shaderHandle);
    gui.shaderHandle = 0;

	if (gui.fontTexture)
	{
		glDeleteTextures(1, &gui.fontTexture);
        ImFontAtlas_SetTexID(igGetIO().Fonts, cast(void*)0);
		gui.fontTexture = 0;
	}

	igShutdown();
    glfwTerminate();
}

void update()
{
    glfwPollEvents();

	if (!gui.fontTexture)
    {
        gui.init();
        gui.initFontTexture();
    }

	gui.io.DisplaySize = ImVec2(cast(float)window.fbw, cast(float)window.fbh);

    double current_time =  glfwGetTime();
    gui.io.DeltaTime = time > 0.0 ? cast(float)(current_time - time) : cast(float)(1.0f/60.0f);
    time = current_time;

    if (window.focused)
    {
        gui.io.MousePos = ImVec2(window.mouseX * (cast(float)window.fbw / window.w), window.mouseY * (cast(float)window.fbh / window.h));
    }
    else
    {
        gui.io.MousePos = ImVec2(-1,-1);
    }

    for (int i = 0; i < 3; i++)
    {
        gui.io.MouseDown[i] = mousePressed[i] || glfwGetMouseButton(window.handle, i) != 0;
        mousePressed[i] = false;
    }

    gui.io.MouseWheel = mouseWheel;
    mouseWheel = 0.0f;

    glfwSetInputMode(window.handle, GLFW_CURSOR, gui.io.MouseDrawCursor ? GLFW_CURSOR_HIDDEN : GLFW_CURSOR_NORMAL);

	igNewFrame();
}

void render()
{
    glViewport(0, 0, cast(int)gui.io.DisplaySize.x, cast(int)gui.io.DisplaySize.y);
    glClearColor(clearColor[0], clearColor[1], clearColor[2], 0);
    glClear(GL_COLOR_BUFFER_BIT);
    igRender();
    window.swap();
}
