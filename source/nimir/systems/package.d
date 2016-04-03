module nimir.systems;

import nimir.systems.glfw;
import nimir.systems.imgui;

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
GLuint       fontTexture = 0;
int          shaderHandle = 0, vertHandle = 0, fragHandle = 0;
int          attribLocationTex = 0, attribLocationProjMtx = 0;
int          attribLocationPosition = 0, attribLocationUV = 0, attribLocationColor = 0;
uint         vboHandle, vaoHandle, elementsHandle;
float[3]     clearColor = [0.9f, 0.9f, 0.9f];

const GLchar *vertShader =
    "#version 330\n"
        "uniform mat4 ProjMtx;\n"
        "in vec2 Position;\n"
        "in vec2 UV;\n"
        "in vec4 Color;\n"
        "out vec2 Frag_UV;\n"
        "out vec4 Frag_Color;\n"
        "void main()\n"
        "{\n"
        "	Frag_UV = UV;\n"
        "	Frag_Color = Color;\n"
        "	gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
        "}\n";

const GLchar* fragShader =
    "#version 330\n"
        "uniform sampler2D Texture;\n"
        "in vec2 Frag_UV;\n"
        "in vec4 Frag_Color;\n"
        "out vec4 Out_Color;\n"
        "void main()\n"
        "{\n"
        "	Out_Color = Frag_Color * texture( Texture, Frag_UV.st);\n"
        "}\n";

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
            if (action == GLFW_PRESS && button >= 0 && button < 3) mousePressed[button] = true;
        };
        window.onScroll = (handle, xoffset, yoffset)
        {
            mouseWheel += cast(float)yoffset;
        };
        window.onKey = (handle, key, scancode, action, mods)
        {
            imgui.io.KeysDown[key] = action == GLFW_PRESS? true : false;
            imgui.io.KeyCtrl = (mods & GLFW_MOD_CONTROL) != 0;
            imgui.io.KeyShift = (mods & GLFW_MOD_SHIFT) != 0;
            imgui.io.KeyAlt = (mods & GLFW_MOD_ALT) != 0;
        };
        window.onCharacter = (window, codepoint)
        {
            if (codepoint > 0 && codepoint < 0x10000) ImGuiIO_AddInputCharacter(cast(ushort)codepoint);
        };

        imgui.io.KeyMap[ImGuiKey_Tab] = GLFW_KEY_TAB;                 // Keyboard mapping. ImGui will use those indices to peek into the imgui.io.KeyDown[] array.
        imgui.io.KeyMap[ImGuiKey_LeftArrow] = GLFW_KEY_LEFT;
        imgui.io.KeyMap[ImGuiKey_RightArrow] = GLFW_KEY_RIGHT;
        imgui.io.KeyMap[ImGuiKey_UpArrow] = GLFW_KEY_UP;
        imgui.io.KeyMap[ImGuiKey_DownArrow] = GLFW_KEY_DOWN;
        imgui.io.KeyMap[ImGuiKey_Home] = GLFW_KEY_HOME;
        imgui.io.KeyMap[ImGuiKey_End] = GLFW_KEY_END;
        imgui.io.KeyMap[ImGuiKey_Delete] = GLFW_KEY_DELETE;
        imgui.io.KeyMap[ImGuiKey_Backspace] = GLFW_KEY_BACKSPACE;
        imgui.io.KeyMap[ImGuiKey_Enter] = GLFW_KEY_ENTER;
        imgui.io.KeyMap[ImGuiKey_Escape] = GLFW_KEY_ESCAPE;
        imgui.io.KeyMap[ImGuiKey_A] = GLFW_KEY_A;
        imgui.io.KeyMap[ImGuiKey_C] = GLFW_KEY_C;
        imgui.io.KeyMap[ImGuiKey_V] = GLFW_KEY_V;
        imgui.io.KeyMap[ImGuiKey_X] = GLFW_KEY_X;
        imgui.io.KeyMap[ImGuiKey_Y] = GLFW_KEY_Y;
        imgui.io.KeyMap[ImGuiKey_Z] = GLFW_KEY_Z;

        imgui.io.RenderDrawListsFn = (data)
        {
            GLint last_program, last_texture;
            glGetIntegerv(GL_CURRENT_PROGRAM, &last_program);
            glGetIntegerv(GL_TEXTURE_BINDING_2D, &last_texture);
            glEnable(GL_BLEND);
            glBlendEquation(GL_FUNC_ADD);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glDisable(GL_CULL_FACE);
            glDisable(GL_DEPTH_TEST);
            glEnable(GL_SCISSOR_TEST);
            glActiveTexture(GL_TEXTURE0);
        	const float[4][4] orthoProjection =
        	[
        		[ 2.0f/imgui.io.DisplaySize.x, 0.0f,                         0.0f, 0.0f ],
        		[ 0.0f,			               2.0f/-imgui.io.DisplaySize.y, 0.0f, 0.0f ],
        		[ 0.0f,			               0.0f,			            -1.0f, 0.0f ],
        		[ -1.0f,		               1.0f,			             0.0f, 1.0f ],
        	];
        	glUseProgram(shaderHandle);
        	glUniform1i(attribLocationTex, 0);
        	glUniformMatrix4fv(attribLocationProjMtx, 1, GL_FALSE, &orthoProjection[0][0]);

            glBindVertexArray(vaoHandle);
            glBindBuffer(GL_ARRAY_BUFFER, vboHandle);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementsHandle);

            foreach (n; 0..data.CmdListsCount)
            {
                ImDrawIdx* idx_buffer_offset;

                auto countVertices = ImDrawList_GetVertexBufferSize(data.CmdLists[n]);
                auto countIndices = ImDrawList_GetIndexBufferSize(data.CmdLists[n]);

                glBufferData(GL_ARRAY_BUFFER, countVertices * ImDrawVert.sizeof, cast(GLvoid*)ImDrawList_GetVertexPtr(data.CmdLists[n],0), GL_STREAM_DRAW);
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, countIndices * ImDrawIdx.sizeof, cast(GLvoid*)ImDrawList_GetIndexPtr(data.CmdLists[n],0), GL_STREAM_DRAW);

                foreach(i; 0..ImDrawList_GetCmdSize(data.CmdLists[n]))
                {
                    auto pcmd = ImDrawList_GetCmdPtr(data.CmdLists[n], i);

                    if (pcmd.UserCallback)
                    {
                        pcmd.UserCallback(data.CmdLists[n], pcmd);
                    }
                    else
                    {
                        glBindTexture(GL_TEXTURE_2D, cast(GLuint)pcmd.TextureId);
                        glScissor(cast(int)pcmd.ClipRect.x, cast(int)(imgui.io.DisplaySize.y - pcmd.ClipRect.w), cast(int)(pcmd.ClipRect.z - pcmd.ClipRect.x), cast(int)(pcmd.ClipRect.w - pcmd.ClipRect.y));
                        glDrawElements(GL_TRIANGLES, pcmd.ElemCount, GL_UNSIGNED_SHORT, idx_buffer_offset);
                    }

                    idx_buffer_offset += pcmd.ElemCount;
                }
            }

            glBindVertexArray(0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glUseProgram(last_program);
            glDisable(GL_SCISSOR_TEST);
            glBindTexture(GL_TEXTURE_2D, last_texture);
        };
        imgui.io.SetClipboardTextFn = (ct){window.clipboardText = ct;};
        imgui.io.GetClipboardTextFn = (){return window.clipboardText;};

        version (Win32) imgui.io.ImeWindowHandle = glfwGetWin32Window(window.handle);
        cast() imgui.io.IniFilename = null;

        imgui.style.Colors[ImGuiCol_Text]                  = ImVec4(1.00f, 1.00f, 1.00f, 1.00f);
        imgui.style.Colors[ImGuiCol_TextDisabled]          = ImVec4(0.60f, 0.60f, 0.60f, 1.00f);

        imgui.style.Colors[ImGuiCol_WindowBg]              = ImVec4(0.20f, 0.20f, 0.20f, 1.00f);
        imgui.style.Colors[ImGuiCol_ChildWindowBg]         = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
        imgui.style.Colors[ImGuiCol_Border]                = ImVec4(0.60f, 0.60f, 0.60f, 0.80f);
        imgui.style.Colors[ImGuiCol_BorderShadow]          = ImVec4(1.00f, 1.00f, 1.00f, 0.00f);
        imgui.style.Colors[ImGuiCol_FrameBg]               = ImVec4(0.70f, 0.70f, 0.70f, 0.40f);
        imgui.style.Colors[ImGuiCol_FrameBgHovered]        = ImVec4(0.50f, 0.50f, 0.50f, 0.40f);
        imgui.style.Colors[ImGuiCol_FrameBgActive]         = ImVec4(1.00f, 0.60f, 0.30f, 0.40f);
        imgui.style.Colors[ImGuiCol_TitleBg]               = ImVec4(0.40f, 0.40f, 0.40f, 0.25f);
        imgui.style.Colors[ImGuiCol_TitleBgCollapsed]      = ImVec4(0.40f, 0.40f, 0.40f, 0.25f);
        imgui.style.Colors[ImGuiCol_TitleBgActive]         = ImVec4(0.40f, 0.40f, 0.40f, 0.25f);
        imgui.style.Colors[ImGuiCol_MenuBarBg]             = ImVec4(0.40f, 0.40f, 0.40f, 0.25f);
        imgui.style.Colors[ImGuiCol_ScrollbarBg]           = ImVec4(0.98f, 0.98f, 0.98f, 0.53f);
        imgui.style.Colors[ImGuiCol_ScrollbarGrab]         = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        imgui.style.Colors[ImGuiCol_ScrollbarGrabHovered]  = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        imgui.style.Colors[ImGuiCol_ScrollbarGrabActive]   = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);

        imgui.style.Colors[ImGuiCol_ComboBg]               = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        imgui.style.Colors[ImGuiCol_CheckMark]             = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        imgui.style.Colors[ImGuiCol_SliderGrab]            = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        imgui.style.Colors[ImGuiCol_SliderGrabActive]      = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        imgui.style.Colors[ImGuiCol_Button]                = ImVec4(0.20f, 0.20f, 0.20f, 0.60f);
        imgui.style.Colors[ImGuiCol_ButtonHovered]         = ImVec4(0.30f, 0.30f, 0.30f, 0.60f);
        imgui.style.Colors[ImGuiCol_ButtonActive]          = ImVec4(1.00f, 0.60f, 0.30f, 0.60f);
        imgui.style.Colors[ImGuiCol_Header]                = ImVec4(0.20f, 0.20f, 0.20f, 0.60f);
        imgui.style.Colors[ImGuiCol_HeaderHovered]         = ImVec4(0.30f, 0.30f, 0.30f, 0.60f);
        imgui.style.Colors[ImGuiCol_HeaderActive]          = ImVec4(1.00f, 0.60f, 0.30f, 0.60f);
        imgui.style.Colors[ImGuiCol_Column]                = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        imgui.style.Colors[ImGuiCol_ColumnHovered]         = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);
        imgui.style.Colors[ImGuiCol_ColumnActive]          = ImVec4(0.80f, 0.80f, 0.80f, 0.80f);

        imgui.style.Colors[ImGuiCol_ResizeGrip]            = ImVec4(1.00f, 1.00f, 1.00f, 0.00f);
        imgui.style.Colors[ImGuiCol_ResizeGripHovered]     = ImVec4(0.26f, 0.59f, 0.98f, 0.00f);
        imgui.style.Colors[ImGuiCol_ResizeGripActive]      = ImVec4(0.26f, 0.59f, 0.98f, 0.00f);
        imgui.style.Colors[ImGuiCol_CloseButton]           = ImVec4(0.59f, 0.59f, 0.59f, 0.00f);
        imgui.style.Colors[ImGuiCol_CloseButtonHovered]    = ImVec4(0.98f, 0.39f, 0.36f, 1.00f);
        imgui.style.Colors[ImGuiCol_CloseButtonActive]     = ImVec4(0.98f, 0.39f, 0.36f, 1.00f);

        imgui.style.Colors[ImGuiCol_PlotLines]             = ImVec4(0.39f, 0.39f, 0.39f, 1.00f);
        imgui.style.Colors[ImGuiCol_PlotLinesHovered]      = ImVec4(1.00f, 0.43f, 0.35f, 1.00f);
        imgui.style.Colors[ImGuiCol_PlotHistogram]         = ImVec4(0.90f, 0.70f, 0.00f, 1.00f);
        imgui.style.Colors[ImGuiCol_PlotHistogramHovered]  = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);

        imgui.style.Colors[ImGuiCol_TextSelectedBg]        = ImVec4(0.26f, 0.59f, 0.98f, 1.00f);
        imgui.style.Colors[ImGuiCol_TooltipBg]             = ImVec4(1.00f, 1.00f, 1.00f, 0.40f);
        imgui.style.Colors[ImGuiCol_ModalWindowDarkening]  = ImVec4(0.20f, 0.20f, 0.20f, 0.35f);

        imgui.style.WindowTitleAlign = ImGuiAlign_Center;

        igPushStyleVar(ImGuiStyleVar_WindowRounding, 4.0f);
    	igPushStyleVar(ImGuiStyleVar_FrameRounding, 2.0f);
    }
    return initialized;
}

void quit()
{
    if (vaoHandle) glDeleteVertexArrays(1, &vaoHandle);
    if (vboHandle) glDeleteBuffers(1, &vboHandle);
    if (elementsHandle) glDeleteBuffers(1, &elementsHandle);
    vaoHandle = 0;
    vboHandle = 0;
    elementsHandle = 0;

    glDetachShader(shaderHandle, vertHandle);
    glDeleteShader(vertHandle);
    vertHandle = 0;

    glDetachShader(shaderHandle, fragHandle);
    glDeleteShader(fragHandle);
    fragHandle = 0;

    glDeleteProgram(shaderHandle);
    shaderHandle = 0;

	if (fontTexture)
	{
		glDeleteTextures(1, &fontTexture);
        ImFontAtlas_SetTexID(igGetIO().Fonts, cast(void*)0);
		fontTexture = 0;
	}

	igShutdown();
    glfwTerminate();
}

void update()
{
    glfwPollEvents();

	if (!fontTexture)
    {
    	shaderHandle = glCreateProgram();
    	vertHandle = glCreateShader(GL_VERTEX_SHADER);
    	fragHandle = glCreateShader(GL_FRAGMENT_SHADER);
    	glShaderSource(vertHandle, 1, &vertShader, null);
    	glShaderSource(fragHandle, 1, &fragShader, null);
    	glCompileShader(vertHandle);
    	glCompileShader(fragHandle);
    	glAttachShader(shaderHandle, vertHandle);
    	glAttachShader(shaderHandle, fragHandle);
    	glLinkProgram(shaderHandle);

    	attribLocationTex = glGetUniformLocation(shaderHandle, "Texture");
    	attribLocationProjMtx = glGetUniformLocation(shaderHandle, "ProjMtx");
    	attribLocationPosition = glGetAttribLocation(shaderHandle, "Position");
    	attribLocationUV = glGetAttribLocation(shaderHandle, "UV");
    	attribLocationColor = glGetAttribLocation(shaderHandle, "Color");

        glGenBuffers(1, &vboHandle);
        glGenBuffers(1, &elementsHandle);

        glGenVertexArrays(1, &vaoHandle);
        glBindVertexArray(vaoHandle);
        glBindBuffer(GL_ARRAY_BUFFER, vboHandle);
        glEnableVertexAttribArray(attribLocationPosition);
        glEnableVertexAttribArray(attribLocationUV);
        glEnableVertexAttribArray(attribLocationColor);

    	glVertexAttribPointer(attribLocationPosition, 2, GL_FLOAT, GL_FALSE, ImDrawVert.sizeof, cast(void*)0);
        glVertexAttribPointer(attribLocationUV, 2, GL_FLOAT, GL_FALSE, ImDrawVert.sizeof, cast(void*)ImDrawVert.uv.offsetof);
        glVertexAttribPointer(attribLocationColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, ImDrawVert.sizeof, cast(void*)ImDrawVert.col.offsetof);

    	glBindVertexArray(0);
    	glBindBuffer(GL_ARRAY_BUFFER, 0);

    	ubyte* pixels;
    	int width, height;
    	ImFontAtlas_GetTexDataAsRGBA32(imgui.io.Fonts,&pixels,&width,&height,null);

    	glGenTextures(1, &fontTexture);
    	glBindTexture(GL_TEXTURE_2D, fontTexture);
    	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

    	ImFontAtlas_SetTexID(imgui.io.Fonts, cast(void*)fontTexture);
    }

	int w, h;
	int display_w, display_h;
	glfwGetWindowSize(window.handle, &w, &h);
	glfwGetFramebufferSize(window.handle, &display_w, &display_h);
	imgui.io.DisplaySize = ImVec2(cast(float)display_w, cast(float)display_h);

    double current_time =  glfwGetTime();
    imgui.io.DeltaTime = time > 0.0 ? cast(float)(current_time - time) : cast(float)(1.0f/60.0f);
    time = current_time;

    if (glfwGetWindowAttrib(window.handle, GLFW_FOCUSED))
    {
        double mouse_x, mouse_y;
        glfwGetCursorPos(window.handle, &mouse_x, &mouse_y);
        mouse_x *= cast(float)display_w / w;
        mouse_y *= cast(float)display_h / h;
        imgui.io.MousePos = ImVec2(mouse_x, mouse_y);
    } else {
        imgui.io.MousePos = ImVec2(-1,-1);
    }

    for (int i = 0; i < 3; i++)
    {
        imgui.io.MouseDown[i] = mousePressed[i] || glfwGetMouseButton(window.handle, i) != 0;
        mousePressed[i] = false;
    }

    imgui.io.MouseWheel = mouseWheel;
    mouseWheel = 0.0f;

    glfwSetInputMode(window.handle, GLFW_CURSOR, imgui.io.MouseDrawCursor ? GLFW_CURSOR_HIDDEN : GLFW_CURSOR_NORMAL);

	igNewFrame();
}

void render()
{
    glViewport(0, 0, cast(int)imgui.io.DisplaySize.x, cast(int)imgui.io.DisplaySize.y);
    glClearColor(clearColor[0], clearColor[1], clearColor[2], 0);
    glClear(GL_COLOR_BUFFER_BIT);
    igRender();
    glfwSwapBuffers(window.handle);
}
