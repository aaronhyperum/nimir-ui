module nimir.systems.imgui;

import derelict.imgui.imgui;

static this()
{
    DerelictImgui.load();
}

static ~this()
{

}

final abstract class imgui
{   static:

    @property nothrow ImGuiIO* io ()
    {
        return igGetIO();
    }

    @property nothrow ImGuiStyle* style()
    {
        return igGetStyle();
    }
}
