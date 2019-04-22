
using Revise

##

# for drawing Bayes tree with images (see debug tricks below)
using Cairo, Fontconfig
using Gadfly

using RoME
#  Do some plotting
using RoMEPlotting


## start with an empty factor graph object
fg = initfg()

# Add the first pose :x0
addVariable!(fg, :x0, Pose2)

# Add at a fixed location PriorPose2 to pin :x0 to a starting location (10,10, pi/4)
addFactor!(fg, [:x0], PriorPose2( MvNormal([0.0; 0.0; 0.0], Matrix(Diagonal([0.1;0.1;0.05].^2))) ), autoinit=true )

# Drive around in a hexagon
for i in 0:5
    psym = Symbol("x$i")
    nsym = Symbol("x$(i+1)")
    addVariable!(fg, nsym, Pose2)
    pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
    addFactor!(fg, [psym;nsym], pp, autoinit=false )
end

# Add landmarks with Bearing range measurements
addVariable!(fg, :l1, Point2, labels=["LANDMARK"])
p2br = Pose2Point2BearingRange(Normal(0,0.03),Normal(20.0,0.5))
addFactor!(fg, [:x0; :l1], p2br, autoinit=false )


# Add landmarks with Bearing range measurements
p2br2 = Pose2Point2BearingRange(Normal(0,0.03),Normal(20.0,0.5))
addFactor!(fg, [:x6; :l1], p2br2, autoinit=false )

##

# writeGraphPdf(fg, show=true)

tree = wipeBuildNewTree!(fg, drawpdf=true, show=true, imgs=false)


## continuously draw tree
# @async begin
#   for i in 1:1000
#     drawTree(tree, show=true)
#     sleep(1.0)
#   end
# end


## Manually do tree based initialization

xx, ll = ls(fg)
for var in union(xx,ll)
  @show var, isInitialized(fg, var)
end

# fgc = deepcopy(fg)





## cliq 6

ts6 = @async begin

cliq = tree.cliques[6]
cliq.attributes["label"]

clst = cliqInitSolveUp!(fg, tree, cliq, drawtree=true )

# drawTree(tree, show=true)

end



## cliq 5
# should be initializing with downward marginal message on x1 and x3


ts5 = @async begin

cliq = tree.cliques[5]
cliq.attributes["label"]

cliqInitSolveUp!(fg, tree, cliq, drawtree=true )

# drawTree(tree, show=true)

end





# plotPose(fg, :x0)
# plotPose(fg, :x2)



# cliq 3

ts3 = @async begin

cliq = tree.cliques[3]
cliq.attributes["label"]

while :upsolved != cliqInitSolveUp!(fg, tree, cliq, drawtree=true ); end

# drawTree(tree, show=true)

end


# plotPose(fg, :x6)
# plotPose(fg, :x0)
#


# cliq 4

ts4 = @async begin

cliq = tree.cliques[4]
cliq.attributes["label"]

while :upsolved != cliqInitSolveUp!(fg, tree, cliq, drawtree=true ); end

# drawTree(tree, show=true)

end

# plotPose(fg, :x4)
# drawPoses(fg, to=3)



# stuff = prepCliqInitMsgsDown!(fg,tree,tree.cliques[1])
# plotPose(Pose2(), [stuff[:x5];])




## cliq 2

ts2 = @async begin

cliq = tree.cliques[2]
cliq.attributes["label"]

while :upsolved != cliqInitSolveUp!(fg, tree, cliq, drawtree=true ); end

# drawTree(tree, show=true)

end




# drawTree(tree, show=true)


# plotPose(fg, :x1)
# drawPoses(fg, to=2)


## look at current value for :x3

# stuff = prepCliqInitMsgsDown!(fg,tree,tree.cliques[1])
#
# plotPose(Pose2(), [stuff[:x3];])




# cliq 1

ts1 = @async begin

cliq = tree.cliques[1]
cliq.attributes["label"]

while :upsolved != cliqInitSolveUp!(fg, tree, cliq, drawtree=true ); end

# drawTree(tree, show=true)

end




#

drawPosesLandms(fg, meanmax=:max)
0


#
# plotPose(fg, :x3)
#
#
#
# stuff = treeProductUp(fg, tree, :x5, :x5)
# plotPose(Pose2(), [manikde!(stuff[1], (:Euclid, :Euclid, :Circular))])








## follow with downward inference

IncrementalInference.downMsgPassingRecursive(ExploreTreeType(fg, tree, tree.cliques[1], nothing, NBPMessage[]), N=100, dbg=false, drawpdf=true);

drawTree(tree, show=true)




## debug upsolve

upMsgPassingRecursive(ExploreTreeType(fg, tree, tree.cliques[1], nothing, NBPMessage[]), N=100, dbg=false, drawpdf=true);



drawPosesLandms(fg)






# Initialize :l1 numerical values but do not rerun solver
# ensureAllInitialized!(fg)
pl = drawPosesLandms(fg, meanmax=:max)
Gadfly.draw(Gadfly.PDF("/tmp/test2.pdf"),pl)  # or PNG(...)
@async run(`evince /tmp/test2.pdf`)



##

plotPose(fg, :x3)

##

stuff = treeProductUp(fg, tree, :l1, :l1)

plotKDE(manikde!(stuff[1], (:Euclid, :Euclid)), levels=2)



plotLocalProduct(fg, :x5)

plotKDE(fg, [:x0; :x6; :l1], levels=2, dims=[1;2])


stuff = treeProductUp(fg, tree, :x0, :l1)
L1 = manikde!(stuff[1], (:Euclid, :Euclid))

X0 = getKDE(fg, :x0)
plotKDE([X0; L1], levels=2, dims=[1;2])



stuff = treeProductUp(fg, tree, :x5, :x5)
plotKDE(manikde!(stuff[1], Pose2().manifolds), levels=2)




##

batchSolve!(fg, drawpdf=true, recursive=true)


##

ensureAllInitialized!(fg)


fg.isfixedlag = true
fg.qfl = 99


getData(fg, :x1).ismargin = true



XX1 = deepcopy(getKDE(fg, :x1))

plotPose(Pose2(), [XX1;]) |> SVG("/tmp/test.svg")
@async run(`inkscape /tmp/test.svg`)


plotPose(Pose2(), [getKDE(fg, :x1);]) |> SVG("/tmp/test2.svg")
@async run(`inkscape /tmp/test2.svg`)



# solve
batchSolve!(fg, drawpdf=true)


# redraw
pl = drawPosesLandms(fg, meanmax=:mean)
Gadfly.draw(Gadfly.PDF("/tmp/test3.pdf", 20cm, 10cm),pl)  # or PNG(...)




## testing subgraph

sfg = subgraphFromVerts(fg, [:x0;:x1;:l1], neighbors=2)

writeGraphPdf(sfg, show=true)




plotLocalProduct(fg, :x4)



fgs = deepcopy(fg)




batchSolve!(fgs)



plotPose(fg, [:x1;:x2])


plotPose(fg, [:x1;:x2])



getKDE(sfg, :x1)



plotKDE([getKDE(fg, :x2); getKDE(fgs, :x2)], dims=[1;2], c=["red";"green"], levels=2)



getSym(fg, getCliqAllVarIds(whichCliq(tree, :x1))[2])


tree = wipeBuildNewTree!(fg, drawpdf=true, show=true, imgs=true)

treeProductUp(fg, tree, :x0, :x0)






## Init Process summary`
#
# 1. trigger inits on all child cliques.
# 2. wait for (take!) response from all initUpChannel.
# 3. propagate initdownmsgs to any child cliq that needs down msgs.
# 4. initialize from down init msg and determine if further downward init msgs are required
## Note fully up-solvable only possible if all children completed up-solve


#


using RoMEPlotting


plotPose(fg,:x2)