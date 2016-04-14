module nimir.image;

import std.string;
import std.stdio;
import std.file: exists;
import std.conv;

import derelict.opengl3.gl3;
import imageformats;


class NimirImage
{
public:

    this()
    {
        texture = 0;
    }

    bool init()
    {
        if(inited) deinit();
        glGenTextures(1, &texture);
        return inited;
    }

    bool loadFile(string file, uint channels = 0)
    {
        if(!inited) init();
        if(!exists(file) || channels < 0 || channels > 5) return false;

        image = read_image(file, channels);

        GLint lastTexture;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &lastTexture);

        glBindTexture(GL_TEXTURE_2D, texture);
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, image.c == 3? GL_RGB : GL_RGBA , cast(int)image.w, cast(int)image.h, 0, image.c == 1? GL_RED : image.c == 2? GL_RG : image.c == 3? GL_RGB : GL_RGBA, GL_UNSIGNED_BYTE, cast(void*)data);
            glBindTexture(GL_TEXTURE_2D, lastTexture);
        }
        return true;
    }

    bool loadData(ubyte* data, int width, int height, int channels)
    {
        if(!inited) init();
        if(channels < 0 || channels > 5) return false;

        GLint lastTexture;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &lastTexture);

        glBindTexture(GL_TEXTURE_2D, texture);
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, channels == 3? GL_RGB : GL_RGBA , width, height, 0,  channels == 1? GL_RED : channels == 2? GL_RG : channels == 3? GL_RGB : GL_RGBA, GL_UNSIGNED_BYTE, cast(void*)data);
            glBindTexture(GL_TEXTURE_2D, lastTexture);
        }
        image.w = width;
        image.h = height;
        image.c = cast(ColFmt)channels;
        return true;
    }

    void deinit()
    {
        if(inited) glDeleteTextures(1, &texture);
    }

    @property bool inited()
    {
        return (texture != 0);
    }

    @property ubyte[] data()
    {
        return image.pixels;
    }

    @property int w()
    {
        return cast(int)image.w;
    }

    @property int h()
    {
        return cast(int)image.h;
    }

    @property ref GLuint glTexture()
    {
        return texture;
    }

    ~this()
    {
        if (inited) deinit();
    }

private:

    GLuint texture;
    IFImage image;
}
