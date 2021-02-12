
"""
    abstract type AbstractAtlas end

An abstract class for atlases.
"""
abstract type AbstractAtlas end

"""
    struct RetractionAtlas{
        TInvRetr<:AbstractInverseRetractionMethod,
        TRetr<:AbstractRetractionMethod,
        TBasis<:AbstractBasis,
    } <: AbstractAtlas

An atlas indexed by points on a manifold, such that coordinate transformations are performed
using retractions, inverse retractions and coordinate calculation for a given basis.
"""
struct RetractionAtlas{
    TInvRetr<:AbstractInverseRetractionMethod,
    TRetr<:AbstractRetractionMethod,
    TBasis<:AbstractBasis{<:Any,TangentSpaceType},
} <: AbstractAtlas
    invretr::TInvRetr
    retr::TRetr
    basis::TBasis
end

function RetractionAtlas(
    invretr::AbstractInverseRetractionMethod,
    retr::AbstractRetractionMethod,
)
    return RetractionAtlas(invretr, retr, DefaultOrthonormalBasis())
end
RetractionAtlas() = RetractionAtlas(LogarithmicInverseRetraction(), ExponentialRetraction())

get_default_atlas(M::Manifold) = RetractionAtlas()

"""
    get_point_coordinates(M::Manifold, A::AbstractAtlas, i, p)

Calculate coordinates of point `p` on manifold `M` in chart from atlas `A` at index `i`.
"""
get_point_coordinates(::Manifold, ::AbstractAtlas, ::Any, ::Any)

function get_point_coordinates(M::Manifold, A::AbstractAtlas, i, p)
    x = allocate_result(M, get_point_coordinates, p)
    get_point_coordinates!(M, x, A, i, p)
    return x
end

function allocate_result(M::Manifold, f::typeof(get_point_coordinates), p)
    T = allocate_result_type(M, f, (p,))
    return allocate(p, T, manifold_dimension(M))
end

function get_point_coordinates!(M::Manifold, x, A::RetractionAtlas, i, p)
    return get_coordinates!(M, x, i, inverse_retract(M, i, p, A.invretr), A.basis)
end

function get_point_coordinates(M::Manifold, A::RetractionAtlas, i, p)
    return get_coordinates(M, i, inverse_retract(M, i, p, A.invretr), A.basis)
end

"""
    get_point(M::Manifold, A::AbstractAtlas, i, x)

Calculate point at coordinates `x` on manifold `M` in chart from atlas `A` at index `i`.
"""
get_point(::Manifold, ::AbstractAtlas, ::Any, ::Any)

function get_point(M::Manifold, A::AbstractAtlas, i, x)
    p = allocate_result(M, get_point, x)
    get_point!(M, p, A, i, x)
    return p
end

function allocate_result(M::Manifold, f::typeof(get_point), x)
    T = allocate_result_type(M, f, (x,))
    return allocate(x, T, representation_size(M)...)
end

function get_point(M::Manifold, A::RetractionAtlas, i, x)
    return retract(M, i, get_vector(M, i, x, A.basis), A.retr)
end

function get_point!(M::Manifold, p, A::RetractionAtlas, i, x)
    return retract!(M, p, i, get_vector(M, i, x, A.basis), A.retr)
end

"""
    get_chart_index(M::Manifold, A::AbstractAtlas, p)

Select a chart from atlas `A` for manifold `M` that is suitable for representing
neighborhood of point `p`.
"""
get_chart_index(::Manifold, ::AbstractAtlas, ::Any)

get_chart_index(::Manifold, ::RetractionAtlas, p) = p

"""
    transition_map(M::Manifold, A_from::AbstractAtlas, i_from, A_to::AbstractAtlas, i_to, x)
    transition_map(M::Manifold, A::AbstractAtlas, i_from, i_to, x)

Given coordinates `x` in chart `(A_from, i_from)` of a point on manifold `M`, returns
coordinates of that point in chart `(A_to, i_to)`. If `A_from` and `A_to` are equal, `A_to`
can be omitted.
"""
function transition_map(
    M::Manifold,
    A_from::AbstractAtlas,
    i_from,
    A_to::AbstractAtlas,
    i_to,
    x,
)
    return get_point_coordinates(M, A_to, i_to, get_point(M, A_from, i_from, x))
end

function transition_map(M::Manifold, A::AbstractAtlas, i_from, i_to, x)
    return transition_map(M, A, i_from, A, i_to, x)
end

function transition_map!(
    M::Manifold,
    y,
    A_from::AbstractAtlas,
    i_from,
    A_to::AbstractAtlas,
    i_to,
    x,
)
    return get_point_coordinates!(M, y, A_to, i_to, get_point(M, A_from, i_from, x))
end

function transition_map!(M::Manifold, y, A::AbstractAtlas, i_from, i_to, x)
    return transition_map!(M, y, A, i_from, A, i_to, x)
end

"""
    induced_basis(M::Manifold, A::AbstractAtlas, i, p, VST::VectorSpaceType)

Basis of vector space of type `VST` at point `p` from manifold `M` induced by
chart (`A`, `i`).
"""
induced_basis(M::Manifold, A::AbstractAtlas, i, VST::VectorSpaceType)

function induced_basis(
    M::Manifold,
    A::RetractionAtlas{
        <:AbstractInverseRetractionMethod,
        <:AbstractRetractionMethod,
        <:DefaultOrthonormalBasis,
    },
    i,
    p,
    ::TangentSpaceType,
)
    return A.basis
end
function induced_basis(
    M::Manifold,
    A::RetractionAtlas{
        <:AbstractInverseRetractionMethod,
        <:AbstractRetractionMethod,
        <:DefaultOrthonormalBasis,
    },
    i,
    p,
    ::CotangentSpaceType,
)
    return dual_basis(A.basis)
end

"""
    InducedBasis(vs::VectorSpaceType, A::AbstractAtlas, i)

The basis induced by chart `i` from atlas `A` of vector space of type `vs`.
"""
struct InducedBasis{𝔽,VST<:VectorSpaceType,TA<:AbstractAtlas,TI} <: AbstractBasis{𝔽,VST}
    vs::VST
    A::TA
    i::TI
end

function induced_basis(M::Manifold{𝔽}, A::AbstractAtlas, i, VST::VectorSpaceType) where {𝔽}
    return InducedBasis{𝔽,typeof(VST),typeof(A),typeof(i)}(VST, A, i)
end

"""
    local_metric(M::Manifold, B::InducedBasis, p)

Compute the local metric tensor for vectors expressed in terms of coordinates
in basis `B` on manifold `M`. The point `p` is not checked.
"""
local_metric(::Manifold, ::InducedBasis, ::Any)

function allocate_result(M::PowerManifoldNested, f::typeof(get_point), x)
    return [allocate_result(M.manifold, f, _access_nested(x, i)) for i in get_iterator(M)]
end
function allocate_result(M::PowerManifoldNested, f::typeof(get_point_coordinates), p)
    return invoke(
        allocate_result,
        Tuple{Manifold,typeof(get_point_coordinates),Any},
        M,
        f,
        p,
    )
end
