module nimir.systems.gui;

import derelict.imgui.imgui;
import derelict.opengl3.gl3;

//TODO: In init functions, return OpenGL bound handles to previous state. See image.d.

static this()
{
    DerelictImgui.load();

    gui.io.RenderDrawListsFn = (data)
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
            [ 2.0f/gui.io.DisplaySize.x, 0.0f,                         0.0f, 0.0f ],
            [ 0.0f,			               2.0f/-gui.io.DisplaySize.y, 0.0f, 0.0f ],
            [ 0.0f,			               0.0f,			            -1.0f, 0.0f ],
            [ -1.0f,		               1.0f,			             0.0f, 1.0f ],
        ];
        glUseProgram(gui.shaderHandle);
        glUniform1i(gui.attribLocationTex, 0);
        glUniformMatrix4fv(gui.attribLocationProjMtx, 1, GL_FALSE, &orthoProjection[0][0]);

        glBindVertexArray(gui.vaoHandle);
        glBindBuffer(GL_ARRAY_BUFFER, gui.vboHandle);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gui.elementsHandle);

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
                    glScissor(cast(int)pcmd.ClipRect.x, cast(int)(gui.io.DisplaySize.y - pcmd.ClipRect.w), cast(int)(pcmd.ClipRect.z - pcmd.ClipRect.x), cast(int)(pcmd.ClipRect.w - pcmd.ClipRect.y));
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
}

static ~this()
{

}

final abstract class gui
{   static:

    GLuint       fontTexture = 0;
    int          shaderHandle = 0, vertHandle = 0, fragHandle = 0;
    int          attribLocationTex = 0, attribLocationProjMtx = 0;
    int          attribLocationPosition = 0, attribLocationUV = 0, attribLocationColor = 0;
    uint         vboHandle, vaoHandle, elementsHandle;

    @property nothrow ImGuiIO* io ()
    {
        return igGetIO();
    }

    @property nothrow ImGuiStyle* style()
    {
        return igGetStyle();
    }

    void initFontTexture()
    {
    	ubyte* pixels;
    	int width, height;
    	ImFontAtlas_GetTexDataAsRGBA32(io.Fonts,&pixels,&width,&height,null);

    	glGenTextures(1, &fontTexture);
    	glBindTexture(GL_TEXTURE_2D, fontTexture);
    	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

    	ImFontAtlas_SetTexID(io.Fonts, cast(void*)fontTexture);
    }

    void initRenderProgram()
    {
        const GLchar* vertShader =
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
    }
}
