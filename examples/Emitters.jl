
module example

using OpticSimVis
using OpticSim, OpticSim.Geometry, OpticSim.Emitters
using StaticArrays

println("Start [$(splitext(basename(@__FILE__))[1])]")

#---------------------------------------------------------------
# Create the Application Object and the 3D viewer
#---------------------------------------------------------------
app = App()
prop!(app, :title, "OpticSimVis Example - Emitters")


scene = Scene(openWindow = false)
set_Z_up!(scene)
grid!(scene, false)
axes!(scene, false)
cameraTransform!(scene, lookAt(SVector(1.0, 1.0, -1.0), zero3()))
cameraPlanes!(scene, 0.1, 1000.0)

#---------------------------------------------------------------
# Define Variables
#---------------------------------------------------------------
# shape = "plane", "sphere", "cylinder"
origin = addVariable!(app, Variable(name="origin", type="string",value="rectGrid"))
direction = addVariable!(app, Variable(name="direction", type="string",value="constant"))
power = addVariable!(app, Variable(name="power", type="string",value="lambertian"))

O_RectUniformSamples = addVariable!(app, Variable(name="O_RectUniformSamples", type="number",value=10))
O_RectGridResolution = addVariable!(app, Variable(name="O_RectGridResolution", type="number",value=5))
O_HexapolarRings = addVariable!(app, Variable(name="O_HexapolarRings", type="number",value=5))



#---------------------------------------------------------------
# Define Controls
#---------------------------------------------------------------
ui = VContainer(
    HContainer(
        Label("Origin"),
        ButtonToggle(
            variable="origin",
            options = [
                Dict(:key=>"point", :value=>"Point"),
                Dict(:key=>"rectUniform", :value=>"Rectangle Uniform"),
                Dict(:key=>"rectGrid", :value=>"Rectangle Grid"),
                Dict(:key=>"hexapolar", :value=>"Hexapolar"),
            ]
        ),  
    ),
    HContainer(
        Label("Direction"),
        ButtonToggle(
            variable="direction",
            options = [
                Dict(:key=>"constant", :value=>"Constant"),
                Dict(:key=>"rectGrid", :value=>"Rectangle Grid"),
                Dict(:key=>"uniformCone", :value=>"Uniform Cone"),
                Dict(:key=>"hexapolarCone", :value=>"Hexapolar Cone"),
            ]
        ),  
    ),
    HContainer(
        Label("Power"),
        ButtonToggle(
            variable="power",
            options = [
                Dict(:key=>"lambertian", :value=>"Lambertian"),
                Dict(:key=>"cosine", :value=>"Cosine"),
                Dict(:key=>"gaussian", :value=>"Gaussian"),
            ]
        ),  
    ),

    ExpansionPanel(
        title="Parameters",
        subtitle="fine tune the emitters parameters",
        content = VContainer(
            Slider(
                text="O: Rect Uniform Samples",
                trailing_text="[\$()]",
                min=1,
                max=1000,
                value=10,
                variable="O_RectUniformSamples"
            ),  
            Slider(
                text="O: Rect Grid Resolution",
                trailing_text="[\$()]",
                min=2,
                max=50,
                value=5,
                variable="O_RectGridResolution"
            ),  
            Slider(
                text="O: Hexapolar Rings",
                trailing_text="[\$()]",
                min=1,
                max=20,
                value=2,
                variable="O_HexapolarRings"
            ),  

        ),
    ),        

    MeshCatViewer(
        url =  OpticSimVis.url(scene),
        width = "100%",
        height = "600px",
    ),        


)
controls!(app, ui)

#---------------------------------------------------------------
# Render the MLA
#---------------------------------------------------------------

function render()
    clear(scene)

    # axes_mat = Material(color=RGBA(0.7, 0.2, 0.1, 1.0))
    # axes = Axes(tr=transform(SVector(0.0, 0.0, 0.0)),  name="My Axes", axes_scale=0.2)
    # parent!(axes , root(scene))


    local local_frame = Transform(Vec3(0.0, 0.0, 0.0), Vec3(0.0, 0.0, 1.0))

    (origin[] == "point")           && (O = Emitters.Origins.Point())
    (origin[] == "rectUniform")     && (O = Emitters.Origins.RectUniform(1.0, 1.0, O_RectUniformSamples[]))
    (origin[] == "rectGrid")        && (O = Emitters.Origins.RectGrid(1.0, 1.0, O_RectGridResolution[], O_RectGridResolution[]))
    (origin[] == "hexapolar")       && (O = Emitters.Origins.Hexapolar(O_HexapolarRings[], 0.5, 0.5))

    (direction[] == "constant")     && (D = Emitters.Directions.Constant())
    (direction[] == "rectGrid")     && (D = Emitters.Directions.RectGrid(1.0, 1.0, 4, 4))
    (direction[] == "uniformCone")  && (D = Emitters.Directions.UniformCone(deg2rad(30), 50))
    (direction[] == "hexapolarCone")&& (D = Emitters.Directions.HexapolarCone(deg2rad(30), 5))

    (power[] == "lambertian")       && (P = Emitters.AngularPower.Lambertian())
    (power[] == "cosine")           && (P = Emitters.AngularPower.Cosine(10.0))
    (power[] == "gaussian")         && (P = Emitters.AngularPower.Gaussian(2.0, 2.0))

    local S = Emitters.Spectrum.Uniform()
    local Tr = local_frame
    source = Emitters.Sources.Source(Tr, S, O, D, P)    

    OpticSimVis.draw!(scene, source; debug=true)
end


#---------------------------------------------------------------
# setup the render function and run the UI App
#---------------------------------------------------------------
renderFunction!(app, render)
OpticSimVis.run(app)


println("End [$(splitext(basename(@__FILE__))[1])]")


end # module test