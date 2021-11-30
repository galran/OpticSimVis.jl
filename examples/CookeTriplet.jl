module Example

using Glimmer, Glimmer.FlexUI
using OpticSim, OpticSim.Geometry, OpticSim.Emitters
using OpticSimVis
using DataFrames
using StaticArrays
using TableView

println("Start [$(splitext(basename(@__FILE__))[1])]")

#---------------------------------------------------------------
# define the application and some basic properties such as title and initial window size
#---------------------------------------------------------------
app = App()
prop!(app, :title, "Glimmer Example - Luxor")
prop!(app, :winInitWidth, 1400)
prop!(app, :winInitHeight,1200)

#---------------------------------------------------------------
# define the 3D Viewer
#---------------------------------------------------------------
scene = Scene(openWindow = false)
set_Z_up!(scene)
grid!(scene, false)
axes!(scene, false)
cameraTransform!(scene, lookAt(SVector(1.0, 1.0, 0.0)*50, SVector(0.0, 0.0, 0.0)*50))
cameraPlanes!(scene, 0.1, 1000.0)


#---------------------------------------------------------------
# Define Variables
#---------------------------------------------------------------
perscription_html = addVariable!(app, Variable(name="perscription_html", type="string",value=""))
radius1 = addVariable!(app, Variable(name="radius1", type="flota64",value=26))
radius2 = addVariable!(app, Variable(name="radius2", type="flota64",value=66))
count = addVariable!(app, Variable(name="count", type="flota64",value=16))

image = addVariable!(app, Variable(name="image", type="image", value="", ))

#---------------------------------------------------------------
# Define Controls
#---------------------------------------------------------------
ui = VContainer(
    Card(
        title="Controls",
        content=HContainer(
            Card(
                title="Radius 1",
                content=VContainer(
                    Slider(
                        text="Radius 1",
                        trailingText="[\$()]",
                        min=15,
                        max=40,
                        value=26,
                        variable="radius1"
                    ),  
                    Field(
                        input="number",
                        label="Radius 1",
                        hint ="Save Field as the Slider above",
                        variable="radius1",
                    ),  
                ),
            ),
            Card(
                title="Radius 2",
                content=VContainer(
                    Slider(
                        text="Radius 2",
                        trailingText="[\$()]",
                        min=15,
                        max=100,
                        value=26,
                        variable="radius2"
                    ),  
                    Field(
                        input="number",
                        label="Radius 2",
                        hint ="Save Field as the Slider above",
                        variable="radius2",
                    ),  
                ),
            ),
        ),              
    ),

    Card(
        title="Perscription",
        # subtitle="Currently, Glimmer does not contain a GRID component, but allow you to utilize existing GRID component such as the one in the TableView package.",
        content=VContainer(
            RawHTML(
                html="\$(perscription_html)",
                style="width: 100%; height: 300px;"
            ),
        ),
    ),

    MeshCatViewer(
        url =  OpticSimVis.url(scene),
        width = "100%",
        height = "600px",
    ),        

    Glimmer.exampleSourceAsCard(@__FILE__),     # add the source code of the example as the last control
)
# set the controls for the application
controls!(app, ui)

#---------------------------------------------------------------
# the render function - preparing the image
#---------------------------------------------------------------
function updatePerscription(df::DataFrame)
    table_data = TableView.showtable(df)
    perscription_html[] = renderHTML(table_data)
    Glimmer.FlexUI.forceUpdateControls!(app)
end


function render()
    clear(scene)

    Air = OpticSim.Air
    g1, g2 = OpticSim.SCHOTT.N_SK16, OpticSim.SCHOTT.N_SF2

    df = DataFrame(
        SurfaceType  = ["Object", "Standard", "Standard", "Standard", "Stop", "Standard", "Standard", "Image"],
        Radius       = [Inf,      26.777,     66.604,     -35.571,    35.571, 35.571,     -26.777,    Inf    ],
        Thickness    = [Inf,      4.0,        2.0,        4.0,        2.0,    4.0,        44.748,     missing],
        Material     = [Air,      g1,         Air,        g2,         Air,    g1,         Air,        missing],
        SemiDiameter = [Inf,      8.580,      7.513,      7.054,      6.033,  7.003,      7.506,      15.0   ],
    )
    df[2,"Radius"] = radius1[]
    df[3,"Radius"] = radius2[]

    updatePerscription(df)


    sys = AxisymmetricOpticalSystem{Float64}(df)

    origins = Origins.Hexapolar(8, 15.0, 15.0)
    directions = Directions.Constant(0.0, 0.0, -1.0)
    s1 = Sources.Source(; origins, directions, sourcenum=1)

    transform = Transform(rotmatd(10, 0, 0), Geometry.unitZ3())
    s2 = Sources.Source(; transform, origins, directions, sourcenum=2)

    raygenerator = Sources.CompositeSource(Transform(), [s1, s2])

    trackallrays = test = colorbysourcenum = true; resolution = (1000, 700)

    # @info "-"^50
    # @info typeof(sys)
    # @info typeof(sys.system)
    # @info typeof(sys.system.assembly)
    # @info "-"^50
    OpticSimVis.draw!(scene, sys.system)

    resetdetector!(sys)
    if (true)
        OpticSimVis.drawtracerays!(
            scene, sys; 
            raygenerator=raygenerator, 
            trackallrays = true, 
            colorbynhits = true, 
            test = true, 
            numdivisions = 100, 
            drawgen = false,
            drawsys = true
        )
    end

    # Vis.drawtracerays(sys; raygenerator, trackallrays, test, colorbysourcenum, resolution)
    # Vis.make2dy(); Vis.save(filename)
    # return sys

end
renderFunction!(app, render)

#---------------------------------------------------------------
# Run the application
#---------------------------------------------------------------
run(app)

println("End [$(splitext(basename(@__FILE__))[1])]")

end # module
