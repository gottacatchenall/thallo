include("./src/include.jl")

function run_test(; n_gen::Int64=500)
    mp::metapop = init_random_metapop()
    g::genome = init_random_genome()
    instance::ibm = init_ibm(mp, g)

    @time run_n_generations(instance, n_gen)
    #Profile.print()
end

function run_batch_ibm()
    m_vals::Array{Float64} = [0.001, 0.005, 0.01]
    s_vals::Array{Float64} = [1.0, 0.5, 0.1]
    k_vals::Array{Int64} = [2000]
    init_poly_ct::Array{Float64} = [3.0]
    n_ef_vals::Array{Int64} = [1]
    n_chromo_vals::Array{Int64} = [5]
    genome_length_vals::Array{Float64} = [100.0]
    n_rep = 1
    n_gen = 500

    id_ct::Int64 = 1

    ibm_pop_file::String = "ibm_pops.csv"
    ibm_genome_file::String = "ibm_genomes.csv"
    fits_file::String = "fits.csv"

    df = DataFrame(id=[],gen=[],jostd=[],gst=[])
    CSV.write(fits_file, df)


    # need to track metadata
    ibm_metadata::DataFrame = DataFrame(id=[], m=[], s=[], k=[], n_ef=[], n_chromo=[], genome_length=[])
    fits_metadata::DataFrame = DataFrame(id=[], m=[], k=[],init_poly_ct=[])

    lf::Int64 = 20

    # init with appropriate ef values?

    mp::metapop = init_random_metapop()
    for ipc in init_poly_ct
        for m in m_vals
            for s in s_vals
                for k in k_vals
                    for n_ef in n_ef_vals
                        for n_chromo in n_chromo_vals
                            for genome_length in genome_length_vals
                                for r = 1:n_rep
                                    set_mp_total_k(mp, k)
                                    g::genome = init_random_genome(n_ef=n_ef, n_chromo=n_chromo, genome_length=genome_length, init_poly_ct=ipc)


                                    # Run IBM
                                    ibm_instance::ibm = init_ibm(mp, g)
                                    update_ibm_metadata(ibm_metadata, id_ct, m, s, k, n_ef, n_chromo, genome_length)
                                    run_n_generations(ibm_instance, n_gen, migration_rate=m, s=s, genome_file=ibm_genome_file, pop_file=ibm_pop_file, id=id_ct, log_freq=lf)

                                    # Run FITS
                                    n_al::Int64 = convert(Int64, ipc)
                                    fits_instance::fits = fits(mp, n_alleles=convert(Int64,ipc), migration_rate=m, log_freq=lf, n_gen=n_gen)
                                    init_fits_uniform_ic(fits_instance)

                                    update_fits_metadata(fits_metadata, id_ct, m, k, ipc)
                                    df = run_fits(fits_instance, id_ct)
                                    CSV.write(fits_file, df, append=true)

                                    id_ct += 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    CSV.write("ibm_metadata.csv", ibm_metadata)
    CSV.write("fits_metadata.csv", fits_metadata)
end

function fitstest()
    n_als = (3, 8, 15)
    n_pops = (20)
    m = (0.001, 0.005, 0.01)
    eff_pop_size_list = (300, 1000, 3000)
    n_gen = 300
    n_rep = 50

    metadata = DataFrame()
    metadata.id = []
    metadata.m = []
    metadata.eff_pop = []
    metadata.n_pops = []
    metadata.n_alleles = []

    df = DataFrame()
    df.id = []
    df.gen = []
    df.jostd = []
    df.gst = []
    CSV.write("output.csv", df)

    log_freq =20
    idct::Int64 = 0
    mp::metapop = init_random_metapop()
    for base_mig in m
        for n_al in n_als
            for n_pop in n_pops
                for eff_pop in eff_pop_size_list
                    set_mp_total_k(mp, eff_pop)
                    for rep = 1:n_rep
                        instance::fits = fits(mp; n_alleles=n_al, migration_rate=base_mig)
                        init_fits_uniform_ic(instance)

                        #df = run_dke(n_gen, n_pop, n_al, base_mig, eff_pop, 10)
                        df = run_fits(instance, idct)

                        push!(metadata.id, idct)
                        push!(metadata.m, base_mig)
                        push!(metadata.eff_pop, eff_pop)
                        push!(metadata.n_pops, n_pop)
                        push!(metadata.n_alleles, n_al)

                        idct += 1
                        CSV.write("output.csv", df, append=true)
                    end
                end
            end
        end
    end
    CSV.write("metadata.csv", metadata)
end

#@time fitstest()
@time run_batch_ibm()
#run_test()

#run_fits_test()
