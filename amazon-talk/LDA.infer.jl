using Distributions, Turing   # load packages
include("topic.data.jl")      # load toy dataset

# Define the LDA model with parameters:
#   K   - topic num         w   - word instances
#   V   - vocabulary      doc   - doc instances
#   M   - doc num           β   - topic prior
#   N   - count of words    α   - word prior
@model LDA(K, V, M, N, w, doc, β, α) = begin
  θ = Vector{Vector{Real}}(M)
  for m = 1:M
    θ[m] ~ Dirichlet(α)
  end

  ϕ = Vector{Vector{Real}}(K)
  for k = 1:K
    ϕ[k] ~ Dirichlet(β)
  end

  z = tzeros(Int, N)    # Turing-safe array
  for n = 1:N
    z[n] ~ Categorical(θ[doc[n]])   # z here is unkown
  end

  for n = 1:N
    w[n] ~ Categorical(ϕ[z[n]])
  end
end

# Collect 1000 samples using a compositional Gibbs sampler which combines
# - Particle Gibbs for discrete variable z
#   * 50 particles are used for PG; 1 iteration in each Gibbs
# - Hamiltonian Monte Carlo with Dual Averaging for θ and ϕ
#   * adaptation-step-num 200, target-accept-rate 0.65 and length 1.5 for HMCDA; 1 iteration in each Gibbs
samples = sample(
  LDA(data=topicdata),
  Gibbs(1000, PG(50, 1, :z), HMCDA(200, 0.65, 1.5, :θ, :ϕ))
)



#####################################
# Below are codes for visualization #
#####################################

# Samples can be got and used like below
ϕs = samples[:ϕ][1:200]   # fetch first 200 samples for ϕ

# Usually the mean of samples are used learning result, e.g. ϕ = Eᵢ[ϕᵢ]
ϕ = mean(samples[:ϕ])

# Save result for vis
include("topic.helper.jl")
# ldaresult = samples2visdata(samples)
# open("/home/kai/projects/Turing-exps/amazon-talk/LDA.result.json", "w") do f
#     JSON.print(f, ldaresult)
# end

for i = 1:length(samples[:ϕ])
  makerectbinplot(samples, i, "frames/LDA")
end
