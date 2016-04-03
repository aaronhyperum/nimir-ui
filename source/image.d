module nimir.image;

import std.string;
import std.stdio;
import std.file: exists;

import derelict.opengl3.gl3;
import imageformats: IFImage, read_image;


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

    bool loadFile(string file, int channels = 0)
    {
        if(!inited) init();
        if(!exists(file) || (channels != 0 && channels != 3 && channels !=4)) return false;

        image = read_image(file, channels);

        return loadData(image.pixels.ptr, cast(int)image.w, cast(int)image.h, image.c);
    }

    bool loadData(ubyte* data, int width, int height, int channels)
    {
        if(!inited) init();
        //if(channels != 1 && channels != 2 && channels != 3 && channels != 4) return false;

        GLint lastTexture;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &lastTexture);

        glBindTexture(GL_TEXTURE_2D, texture);
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, channels == 3? GL_RGB : GL_RGBA , width, height, 0, channels == 1? GL_RED : channels == 2? GL_RG : channels == 3? GL_RGB : GL_RGBA, GL_UNSIGNED_BYTE, cast(void*)data);
            glBindTexture(GL_TEXTURE_2D, lastTexture);
        }
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
