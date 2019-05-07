
# using Revise

##

# for drawing Bayes tree with images (see debug tricks below)
# using Cairo, Fontconfig
# using Gadfly

using RoME

#  Do some plotting
using RoMEPlotting


function driveHex(fgl, posecount::Int)
    # Drive around in a hexagon
    for i in (posecount-1):(posecount-1+5)
        psym = Symbol("x$i")
        posecount += 1
        nsym = Symbol("x$(i+1)")
        addVariable!(fgl, nsym, Pose2)
        pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
        addFactor!(fgl, [psym;nsym], pp, autoinit=false )
    end

    return posecount
end


function offsetHexLeg(fgl::FactorGraph, posecount::Int; direction=:right)
    psym = Symbol("x$(posecount-1)")
    nsym = Symbol("x$(posecount)")
    posecount += 1
    addVariable!(fgl, nsym, Pose2)
    pp = nothing
    if direction == :right
        pp = Pose2Pose2(MvNormal([10.0;0;-pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
    elseif direction == :left
        pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
    end
    addFactor!(fgl, [psym; nsym], pp, autoinit=false )
    return posecount
end



## start with an empty factor graph object
fg = initfg()
fg.isfixedlag = true
fg.qfl = 15
posecount = 0

# Add the first pose :x0
addVariable!(fg, :x0, Pose2)
posecount += 1


# Add at a fixed location PriorPose2 to pin :x0 to a starting location (10,10, pi/4)
addFactor!(fg, [:x0], PriorPose2( MvNormal([0.0; 0.0; 0.0],
                                           Matrix(Diagonal([0.1;0.1;0.05].^2))) ), autoinit=false )

# Add landmarks with Bearing range measurements
addVariable!(fg, :l1, Point2, labels=["LANDMARK"])
p2br = Pose2Point2BearingRange(Normal(0,0.03),Normal(20.0,0.5))
addFactor!(fg, [:x0; :l1], p2br, autoinit=false )



## hex 1

posecount = driveHex(fg, posecount)

# Add landmarks with Bearing range measurements
p2br2 = Pose2Point2BearingRange(Normal(0,0.03),Normal(20.0,0.5))
addFactor!(fg, [Symbol("x$(posecount-1)"); :l1], p2br2, autoinit=false )


# writeGraphPdf(fg, show=true)



tree = batchSolve!(fg, treeinit=true, drawpdf=true, show=true)

drawPosesLandms(fg, meanmax=:max) |> SVG("/tmp/test.svg") || @async run(`eog /tmp/test.svg`)




## hex 2

posecount = offsetHexLeg(fg, posecount, direction=:right)

# Add landmarks with Bearing range measurements
addVariable!(fg, :l2, Point2, labels=["LANDMARK"])
p2br = Pose2Point2BearingRange(Normal(0,0.03),Normal(20.0,0.5))
addFactor!(fg, [Symbol("x$(posecount-1)"); :l2], p2br, autoinit=false )


posecount = driveHex(fg, posecount)


# Add landmarks with Bearing range measurements
p2br2 = Pose2Point2BearingRange(Normal(0,0.03),Normal(20.0,0.5))
addFactor!(fg, [Symbol("x$(posecount-1)"); :l2], p2br2, autoinit=false )

# writeGraphPdf(fg)

tree = wipeBuildNewTree!(fg, drawpdf=true)


## manual initialization to isolate partial init issue

## First half of tree (easy half)

doorder = [:x2; :x4; :x6; :x0; :x7; :l1]
docliqs = map(x->whichCliq(tree, x).index, doorder)


for i in docliqs
  cliq = tree.cliques[i]
  clst = cliqInitSolveUp!(fg, tree, cliq, drawtree=true, limititers=1 )
end


doorder = [:x11; :x9; :x10]
docliqs = map(x->whichCliq(tree, x).index, doorder)

for i in docliqs
  cliq = tree.cliques[i]
  clst = cliqInitSolveUp!(fg, tree, cliq, drawtree=true, limititers=1 )
end
drawTree(tree)



cliq = whichCliq(tree, :x13)
clst = cliqInitSolveUp!(fg, tree, cliq, drawtree=true, limititers=1 )



# first step in getting init down msg is


cliq = whichCliq(tree, :l2)
msgs = prepCliqInitMsgsDown!(fg, tree, cliq)



getData(fg, :x12)








## wait until working


tree = batchSolve!(fg, treeinit=true, drawpdf=true, show=true)


drawPosesLandms(fg, meanmax=:max) |> SVG("/tmp/test.svg") # || @async run(`eog /tmp/test.svg`)









#