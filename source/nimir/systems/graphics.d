module nimir.systems.graphics;
import derelict.opengl3.gl3;

static this()
{
    DerelictGL3.load();
}

static ~this()
{

}

final abstract class graphics
{   static:
    float[3] clearingColor;

    void reloadContext()
    {
        DerelictGL3.reload();
    }

    void clearColor()
    {
        glClearColor(clearingColor[0], clearingColor[1], clearingColor[2], 0);
        glClear(GL_COLOR_BUFFER_BIT);
    }

    void viewPort(int x, int y, int w, int h)
    {
        glViewport(x, y, w, h);
    }
}
