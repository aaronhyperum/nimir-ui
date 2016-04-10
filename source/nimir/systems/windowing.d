module nimir.systems.windowing;
import nimir.systems.graphics;

import derelict.glfw3.glfw3;

import std.string;
import std.stdio;

import std.conv;

enum CursorMode
{
    Normal,
    Hidden,
    Disabled
};

static this()
{
    DerelictGLFW3.load();

    windowing.start();
}

static ~this()
{
    windowing.close();
}

final abstract class windowing
{   static:
    void start()
    {
        glfwSetErrorCallback
        (
            (error,description)
            {
                try { writefln("GLFW Error %s: %s",error, to!string(description)); }
                catch { }
            }
        );
        glfwInit();
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, true);
    }

    void close()
    {
        glfwTerminate();
    }

    void pollInput()
    {
        glfwPollEvents();
    }
}

class Window
{
    this(int x, int y, string t)
    {
        handle = glfwCreateWindow(x, y, t.toStringz, null, null);

        glfwMakeContextCurrent(handle);
        glfwInit();

        graphics.reloadContext();
    }

    ~this()
    {
    }

    GLFWwindow* handle;

    @property bool shouldRun()
    {
        return !glfwWindowShouldClose(handle);
    }

    version(Win32) @property void* win32()
    {
        return glfwGetWin32Window(handle);
    }

    @property int focused()
    {
        return glfwGetWindowAttrib(handle, GLFW_FOCUSED);
    }

    @property void showCursor(bool show)
    {
        glfwSetInputMode(handle, GLFW_CURSOR, show ? GLFW_CURSOR_NORMAL : GLFW_CURSOR_HIDDEN);
    }

    @property extern(C) const(char)* clipboardText() nothrow
    {
        return glfwGetClipboardString(handle);
    }

    @property extern(C) void clipboardText(const(char)* text) nothrow
    {
        glfwSetClipboardString(handle, text);
    }

    @property int w()
    {
        int w, h;
        glfwGetWindowSize(handle, &w, &h);
        return w;
    }

    @property void w(int w)
    {
        int h;
        glfwGetWindowSize(handle, null, &h);
        glfwSetWindowSize(handle, w, h);

    }

    @property int h()
    {
        int w, h;
        glfwGetWindowSize(handle, &w, &h);
        return h;
    }

    @property void h(int h)
    {
        int w;
        glfwGetWindowSize(handle, &w, null);
        glfwSetWindowSize(handle, w, h);
    }

    @property int fbw()
    {
        int w, h;
        glfwGetFramebufferSize(handle, &w, &h);
        return w;
    }

    @property int fbh()
    {
        int w, h;
        glfwGetFramebufferSize(handle, &w, &h);
        return h;
    }

    @property double mouseX()
    {
        double x, y;
        glfwGetCursorPos(handle, &x, &y);
        return x;
    }

    @property double mouseY()
    {
        double x, y;
        glfwGetCursorPos(handle, &x, &y);
        return y;
    }

    @property void cursorMode(CursorMode mode)
    {
        glfwSetInputMode(handle, GLFW_CURSOR, mode == CursorMode.Normal? GLFW_CURSOR_NORMAL : mode == CursorMode.Hidden? GLFW_CURSOR_HIDDEN :  GLFW_CURSOR_DISABLED);
    }

    @property extern(C) void onMouse(void function(GLFWwindow*, int, int, int) nothrow callback)
    {
        glfwSetMouseButtonCallback(handle, callback);
    }

    @property extern(C) void onScroll(void function(GLFWwindow*, double, double) nothrow callback)
    {
        glfwSetScrollCallback(handle, callback);
    }

    @property extern(C) void onKey(void function(GLFWwindow*, int, int, int, int) nothrow callback)
    {
        glfwSetKeyCallback(handle, callback);
    }

    @property extern(C) void onCharacter(void function(GLFWwindow*, uint) nothrow callback)
    {
        glfwSetCharCallback(handle, callback);
    }

    void swap()
    {
        glfwSwapBuffers(handle);
    }
}
