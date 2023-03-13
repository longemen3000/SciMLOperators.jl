#
using SciMLOperators, LinearAlgebra
using Random

Random.seed!(0)
N = 8
K = 12

@testset "ScalarOperator" begin
    a = rand()
    b = rand()
    x = rand()
    α = ScalarOperator(x)
    u = rand(N,K)

    @test α isa ScalarOperator
    @test iscached(α)
    @test issquare(α)
    @test islinear(α)

    @test convert(Number, α) isa Number
    @test convert(ScalarOperator, a) isa ScalarOperator

    @test size(α) == ()
    @test isconstant(α)

    v=copy(u); @test lmul!(α, u) ≈ v * x
    v=copy(u); @test rmul!(u, α) ≈ x * v

    v=rand(N,K); @test mul!(v, α, u) ≈ u * x
    v=rand(N,K); w=copy(v); @test mul!(v, α, u, a, b) ≈ a*(x*u) + b*w

    v=rand(N,K); @test ldiv!(v, α, u) ≈ u / x
    w=copy(u);   @test ldiv!(α, u) ≈ w / x

    X=rand(N,K); Y=rand(N,K); Z=copy(Y); a=rand(); aa=ScalarOperator(a);
    @test axpy!(aa,X,Y) ≈ a*X+Z

    # Test that ScalarOperator's remain AbstractSciMLScalarOperator's under common ops
    @test α + α isa SciMLOperators.AddedScalarOperator
    (α + α) * u ≈ x * u + x * u
    @test α * α isa SciMLOperators.ComposedScalarOperator
    (α * α) * u ≈ x * x * u
    @test inv(α) isa SciMLOperators.InvertedScalarOperator
    inv(α) * u ≈ 1/x * u
    @test α * inv(α) isa SciMLOperators.ComposedScalarOperator
    α * inv(α) * u ≈ u
    @test α / α isa SciMLOperators.ComposedScalarOperator
    α * α * u ≈ u

    # Test combination with other operators
    for op in (MatrixOperator(rand(N, N)), SciMLOperators.IdentityOperator(N))
        @test α + op isa SciMLOperators.AddedOperator
        @test (α + op) * u ≈ x * u + op * u
        @test α * op isa SciMLOperators.ScaledOperator
        @test (α * op) * u ≈ x * (op * u)
        @test all(map(T -> (T isa SciMLOperators.ScaledOperator), (α / op, op / α, op \ α, α \ op)))
        @test (α / op) * u ≈ (op \ α) * u ≈ α * (op \ u)
        @test (op / α) * u ≈ (α \ op) * u ≈ 1/α * op * u
    end
end

@testset "ScalarOperator update test" begin
    u = ones(N,K)
    v = zeros(N,K)
    p = rand()
    t = rand()

    α = ScalarOperator(0.0; update_func=(a,u,p,t) -> p)
    β = ScalarOperator(0.0; update_func=(a,u,p,t) -> t)

    @test !isconstant(α)
    @test !isconstant(β)

    @test α(u,p,t)   ≈ p * u
    @test α(v,u,p,t) ≈ p * u

    num = α + 2 / β * 3 - 4
    val = p + 2 / t * 3 - 4

    @test num(u,p,t)   ≈ val * u
    @test num(v,u,p,t) ≈ val * u

    @test convert(Number, num) ≈ val
end
#