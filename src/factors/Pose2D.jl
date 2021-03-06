
"""
$(TYPEDEF)

Rigid transform between two Pose2's, assuming (x,y,theta).

Related

Pose3Pose3, Point2Point2, MutablePose2Pose2Gaussian, DynPose2, InertialPose3
"""
struct Pose2Pose2{T} <: IncrementalInference.FunctorPairwise where {T <: IIF.SamplableBelief}
  z::T
  Pose2Pose2{T}() where {T <: IIF.SamplableBelief} = new{T}()
  Pose2Pose2{T}(z1::T) where {T <: IIF.SamplableBelief} = new{T}(z1)
end
Pose2Pose2(z::T) where {T <: IIF.SamplableBelief} = Pose2Pose2{T}(z)

getSample(s::Pose2Pose2{<:IIF.SamplableBelief}, N::Int=1) = (rand(s.z,N), )
function (s::Pose2Pose2{<:IIF.SamplableBelief})(
            res::Vector{Float64},
            userdata,
            idx::Int,
            meas::Tuple,
            wxi::Array{Float64,2},
            wxj::Array{Float64,2}  )
  #
  wXjhat = SE2(wxi[1:3,idx])*SE2(meas[1][1:3,idx])
  jXjhat = SE2(wxj[1:3,idx]) \ wXjhat
  se2vee!(res, jXjhat)
  nothing
end




# NOTE, serialization support -- will be reduced to macro in future
# ------------------------------------

"""
$(TYPEDEF)
"""
mutable struct PackedPose2Pose2  <: IncrementalInference.PackedInferenceType
  datastr::String
  PackedPose2Pose2() = new()
  PackedPose2Pose2(x::String) = new(x)
end
function convert(::Type{Pose2Pose2}, d::PackedPose2Pose2)
  return Pose2Pose2(extractdistribution(d.datastr))
end
function convert(::Type{PackedPose2Pose2}, d::Pose2Pose2)
  return PackedPose2Pose2(string(d.z))
end



function compare(a::Pose2Pose2,b::Pose2Pose2; tol::Float64=1e-10)
    TP = true
    TP = TP && norm(a.z.μ-b.z.μ) < (tol + 1e-5)
    TP = TP && norm(a.z.Σ.mat-b.z.Σ.mat) < tol
    return TP
end

## Deprecated
# function Pose2Pose2(mean::Array{Float64,1}, cov::Array{Float64,2}, w::Vector{Float64})
#   @warn "Pose2Pose2(mu,cov,w) is deprecated in favor of Pose2Pose2(T(...)) -- use for example Pose2Pose2(MvNormal(mu, cov))"
#   Pose2Pose2(MvNormal(mean, cov))
# end
