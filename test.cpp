#include <iostream>
#include <nanogui/screen.h>
#include <nanogui/window.h>
#include <nanogui/layout.h>
#include <nanogui/button.h>
#include <nanogui/glutil.h>
#include <nanogui/label.h>
#include <nanogui/theme.h>
#include <nanogui/formhelper.h>
#include <nanogui/slider.h>
#include "Resource.h"


using namespace std;
using nanogui::Screen;
using nanogui::Window;
using nanogui::GroupLayout;
using nanogui::Button;
using nanogui::Vector2f;
using nanogui::MatrixXu;
using nanogui::MatrixXf;
using nanogui::Label;


int main() {

    nanogui::init();

    /**
     * Create a screen, add a window.
     * To the window add a label and a slider widget.
     */

    Screen app{{1024 / 2, 768 / 2}, "NanoGUI Test"};

    Window window{&app, ""};
    window.setPosition({15, 15});
    window.setLayout(new GroupLayout(5, 5, 0, 0));

    Label *l = new Label(&window,"MODULATION","sans-bold");
    l->setFontSize(10);
    nanogui::Slider *slider = new nanogui::Slider(&window);
    slider->setValue(0.5f);
    float modulation = 5.0f;
    slider->setCallback([&modulation](float value) { modulation = value * 10.0f; });

    // Do the layout calculations based on what was added to the GUI
    app.performLayout();


    /**
     * Load GLSL shader code from embedded resources
     * See: https://github.com/cyrilcode/embed-resource
     */
    nanogui::GLShader mShader;
    Resource vertShader = LOAD_RESOURCE(vert_glsl);
    Resource fragShader = LOAD_RESOURCE(frag_glsl);
    mShader.init("raymarching_shader",
                 string(vertShader.data(), vertShader.size()),
                 string(fragShader.data(), fragShader.size())
    );

    /**
     * Fill the screen with a rectangle (2 triangles)
     */
    MatrixXu indices(3, 2);
    indices.col(0) << 0, 1, 2;
    indices.col(1) << 2, 1, 3;
    MatrixXf positions(3, 4);
    positions.col(0) << -1, -1, 0;
    positions.col(1) <<  1, -1, 0;
    positions.col(2) <<  -1,  1, 0;
    positions.col(3) << 1,  1, 0;
    // bind the shader and upload vertex positions and indices
    mShader.bind();
    mShader.uploadIndices(indices);
    mShader.uploadAttrib("a_position", positions);

    // Set initial value for modulation uniform
    mShader.setUniform("modulation", modulation);

    // Set resolution and screenRatio uniforms
    int fboWidth, fboHeight;
    glfwGetFramebufferSize(app.glfwWindow(), &fboWidth, &fboHeight);
    mShader.setUniform("resolution", Vector2f{fboWidth, fboHeight});
    float mx = std::max<float>(fboWidth, fboHeight);
    auto xDim = fboWidth/mx;
    auto yDim = fboHeight/mx;
    mShader.setUniform("screenRatio", Vector2f{xDim, yDim});

    app.drawAll();
    app.setVisible(true);

    /**
     * 10: clear screen
     * 20: set modulation value
     * 30: draw using shader
     * 40: draw GUI
     * 50: goto 10
     */
    while (!glfwWindowShouldClose(app.glfwWindow()))
    {
        glClearColor(0,0,0,1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

        mShader.bind();
        mShader.setUniform("modulation", modulation);

        mShader.drawIndexed(GL_TRIANGLES, 0, 2);

        app.drawWidgets();

        glfwSwapBuffers(app.glfwWindow());
        glfwPollEvents();
    }

    nanogui::shutdown();
    exit(EXIT_SUCCESS);
}
