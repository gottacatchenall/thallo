
function reproduction(instance::ibm)
    n_pops::Int64 = length(instance.mp.populations)
    indivs_by_pop::Array{Array{Int64,1}} = split_by_pop(instance.population_map, n_pops)

    parent_genotypes::Array{Float64, 3} = copy(instance.genotypes)


    i_ct::Int64 = 1
    for p = 1:n_pops
        if (length(indivs_by_pop[p]) > 1)
            mean_w::Float64 = instance.fitness_map[p]
            k::Float64 = instance.mp.populations[p].k
            exp_num_off::Int64 = round(k*mean_w)

            for i = 1:exp_num_off
                parents_index::Array{Int64} = get_parents(indivs_by_pop[p])

                parent1_genome::Array{Float64, 2} = parent_genotypes[parents_index[1], :,:]
                parent2_genome::Array{Float64, 2} = parent_genotypes[parents_index[2], :,:]

                offspring_genome::Array{Float64, 2} = get_new_genome(parent1_genome, parent2_genome, instance.g)

                instance.genotypes[i_ct,:,:] = offspring_genome
                instance.population_map[i_ct] = p
                i_ct += 1
            end
        end
    end

    if (i_ct == 1)
        return @extinct
    end


    # zero out the rest of stuff
    max_n_indivs::Int64 = length(instance.population_map)
    n_loci::Int64 = instance.g.n_loci
    for i = i_ct:max_n_indivs
        #instance.genotypes[i_ct,:,:] = zeros(n_loci, 2)
        instance.population_map[i_ct] = 0
    end

    return @extant

end

function get_new_genome(parent1_genome::Array{Float64, 2}, parent2_genome::Array{Float64, 2}, g::genome)
    n_loci::Int64 = g.n_loci
    offspring_genome::Array{Float64, 2} = zeros(n_loci, 2)
    offspring_genome[:, 1] = get_new_haplotype(parent1_genome, g)
    offspring_genome[:, 2]  = get_new_haplotype(parent2_genome, g)
    return offspring_genome
end

function get_new_haplotype(parent_genome::Array{Float64, 2}, g::genome)
    chromos::Array{chromosome} = g.chromosomes
    n_chromos::Int64 = length(chromos)
    n_loci_this_chr::Int64 = 0
    n_loci::Int64 = g.n_loci

    this_haplotype::Array{Float64,1} = zeros(n_loci)

    locus::Int64 = 1

    for c = 1:n_chromos
        chr_length::Float64 = chromos[c].length / 100.0
        n_cross = rand(Poisson(chr_length))
        n_loci_this_chr = chromos[c].n_loci

        cross_locations::Array{Int64} = zeros(n_cross)
        if (n_cross > 0)
            cross_locations= rand(DiscreteUniform(1, n_loci_this_chr), n_cross)
            sort!(cross_locations)
        end

        cross_ct::Int64 = 1

        # Independent assortment at start of new chromo
        parent_haplotype = rand(DiscreteUniform(1,2))

        for l = 1:n_loci_this_chr
            if (n_cross >= cross_ct)
                if (l == cross_locations[cross_ct])
                    (parent_haplotype == 1) ? parent_haplotype = 2 : parent_haplotype = 1
                    cross_ct += 1
                end
            end

            # put genome in the genome
            this_haplotype[locus] = parent_genome[locus, parent_haplotype]
            locus += 1
        end
    end

    return this_haplotype

end


function get_parents(this_pop_indivs::Array{Int64,1})
    p1::Int64 = this_pop_indivs[rand(1:length(this_pop_indivs))]
    p2::Int64 = p1
    while p2 == p1
        p2 = this_pop_indivs[rand(1:length(this_pop_indivs))]
    end
    return [p1,p2]
end
