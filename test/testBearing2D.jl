# test bearing

using RoME
using Test

@testset "Triangulation test in 2D, 3 beacons" begin

# noise models
lmp_noise = Matrix(Diagonal([0.01;0.01].^2))

# new factor graph
fg = initfg()

# landmarks
addVariable!(fg, :l1, Point2)
addVariable!(fg, :l2, Point2)
addVariable!(fg, :l3, Point2)

addFactor!(fg, [:l1], PriorPoint2(MvNormal([10.0;1.0],lmp_noise)), autoinit=false)
addFactor!(fg, [:l2], PriorPoint2(MvNormal([10.0+sqrt(3)/2;-0.5],lmp_noise)), autoinit=false)
addFactor!(fg, [:l3], PriorPoint2(MvNormal([10.0-sqrt(3)/2;-0.5],lmp_noise)), autoinit=false)

# pose
addVariable!(fg, :x1, Pose2)
addFactor!(fg, [:x1;:l1], Pose2Point2Bearing(Normal(pi/2,0.05)), autoinit=false)
addFactor!(fg, [:x1;:l2], Pose2Point2Bearing(Normal(-pi/6,0.05)), autoinit=false)
addFactor!(fg, [:x1;:l3], Pose2Point2Bearing(Normal(-pi+pi/6,0.05)), autoinit=false)


# manualinit!(fg, :x1, [30.0*randn(2,100);randn(1,100)])

## Look at graph

# drawGraph(fg)


## solve

# getSolverParams(fg).drawtree = true
# getSolverParams(fg).showtree = true


tree,smt,hist = solveTree!(fg)


## Look at results
#
# using RoMEPlotting
# Gadfly.set_default_plot_size(35cm,25cm)
# #
# drawPosesLandms(fg, spscale=0.2) # |> PNG("/home/dehann/Downloads/triangulation.png",20cm,15cm)
# #
# plotPose(fg, :x1, scale=0.1) # |> PNG("/home/dehann/Downloads/triangulationPose.png",20cm,15cm)
# #
# plotFactor(fg,  lsf(fg, Pose2Point2Bearing)[1])
# #
# plotLocalProduct(fg, :x1)



## complete the unit test

pts = getPoints(getKDE(fg, :x1))
pts[1,:] .-= 10.0

N = size(pts,2)

@test 0.8*N < sum(sqrt.(sum(pts[1:2,:].^2,dims=1)) .< 0.3)

@test 0.8*N < sum(abs.(pts[3,:]) .< 0.1)

#


end




@testset "Triangulation test in 2D (opposite), 3 beacons" begin

# noise models
lmp_noise = Matrix(Diagonal([0.01;0.01].^2))

# new factor graph
fg = initfg()

# landmarks
addVariable!(fg, :l1, Point2)
addVariable!(fg, :l2, Point2)
addVariable!(fg, :l3, Point2)

addFactor!(fg, [:l1], PriorPoint2(MvNormal([-10.0;1.0-10.0],lmp_noise)), autoinit=false)
addFactor!(fg, [:l2], PriorPoint2(MvNormal([-10.0+sqrt(3)/2;-0.5-10.0],lmp_noise)), autoinit=false)
addFactor!(fg, [:l3], PriorPoint2(MvNormal([-10.0-sqrt(3)/2;-0.5-10.0],lmp_noise)), autoinit=false)

# pose
addVariable!(fg, :x1, Pose2)
addFactor!(fg, [:x1;:l1], Pose2Point2Bearing(Normal(pi/2,0.05)), autoinit=false)
addFactor!(fg, [:x1;:l2], Pose2Point2Bearing(Normal(-pi/6,0.05)), autoinit=false)
addFactor!(fg, [:x1;:l3], Pose2Point2Bearing(Normal(-pi+pi/6,0.05)), autoinit=false)


manualinit!(fg, :x1, [0.01*randn(2,100);-randn(1,100)])
# manualinit!(fg, :x1, [30.0*randn(2,100);randn(1,100)])

# drawGraph(fg)

tree,smt,hist = solveTree!(fg)

pts = getPoints(getKDE(fg, :x1))
pts[1,:] .+= 10.0
pts[2,:] .+= 10.0

N = size(pts,2)

@test 0.8*N < sum(sqrt.(sum(pts[1:2,:].^2,dims=1)) .< 0.3)

@test 0.8*N < sum(abs.(pts[3,:]) .< 0.1)

#
# using RoMEPlotting
# Gadfly.set_default_plot_size(35cm,25cm)
# drawPosesLandms(fg, spscale=0.2) # |> PNG("/home/dehann/Downloads/triangulation.png",20cm,15cm)
# plotPose(fg, :x1, scale=0.1) # |> PNG("/home/dehann/Downloads/triangulationPose.png",20cm,15cm)
#
# plotLocalProduct(fg, :x1)
#
# plotFactor(fg,  lsf(fg, Pose2Point2Bearing)[1])


end





#
