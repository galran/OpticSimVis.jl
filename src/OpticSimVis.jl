module OpticSimVis

greet() = println("Hello World!")

using CoordinateTransformations
using Rotations
import GeometryBasics
# using GeometryBasics: HyperRectangle, Vec, Point, Mesh
using Colors: RGBA, RGB
import Colors
import ColorSchemes
import FileIO
import MeshIO
import UUIDs

using OpticSim, OpticSim.Geometry, OpticSim.Emitters
using StaticArrays

using Glimmer, Glimmer.FlexUI

include("Misc.jl")

include("OpticSimAPI/General.jl")
include("OpticSimAPI/Emitters.jl")
include("OpticSimAPI/HeadEyeModel.jl")


# export UIVariables
# export FlexUI

        
#------------------------------------------------------------------------------
# EXports
#------------------------------------------------------------------------------
export  Glimmer, 
        FlexUI,
        App,
        set_camera!,
        prop, prop!,

        Scene,
        set_Y_up!,
        set_Z_up!,
        grid!,
        axes!,
        root, root!,
        parent, parent!,
        material, material!,
        Material,
        transform, lookAt,
        rotation,
        local_tr, local_tr!,
        cameraTransform!, cameraPlanes!,
        Box,
        Mesh,
        Arrow,
        Axes,
        LineSegments,
        PointCloud,
        dataPath,
        unitX3,
        unitY3,
        unitZ3,
        zero3,
        cameraTransform!,        
        url,
        clear,
        DummyExport

export  Container,
        Slider,
        Button,        
        MeshCatViewer,
        Label,
        Image,
        PanZoom,
        Field,
        ButtonToggle,
        RadioGroup,
        CheckBox,
        ExpansionPanel, 
        Accordion,
        Tabs,
        Tab,
        Divider,
        Card,

        VContainer,
        HContainer,
        HContainerSpace,
        H1Label,
        H2Label,
        H3Label,
        H4Label,

        DummyExport

export  BasicValidation, on, Variable
export  FlexUI, addVariable!, prop, prop!, controls, controls!, renderFunction, renderFunction!


end # module
