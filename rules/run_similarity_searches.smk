rule run_blastn:
    """
    Run NCBI blastn to search nucleotide database with assembly query.
    """
    input:
        fasta='{assembly}.fasta',
        db='blast/{name}.root.{root}{masked}.nal'
    output:
        '{assembly}.blastn.{name}.root.{root}{masked}.out'
    wildcard_constraints:
        root='\d+',
        masked='.[fm][ulins\d\.]+'
    params:
        db=lambda wc: "%s.root.%s%s" % (wc.name,wc.root,wc.masked),
        evalue=lambda wc:similarity[wc.name]['evalue'],
        max_target_seqs=lambda wc:similarity[wc.name]['max_target_seqs']
    conda:
         '../envs/blast.yaml'
    threads: 32
    resources:
        threads=32
    shell:
        'cd blast && \
        blastn \
            -query ../{input.fasta} \
            -db {params.db} \
            -outfmt "6 qseqid staxids bitscore std" \
            -max_target_seqs {params.max_target_seqs} \
            -max_hsps 1 \
            -evalue {params.evalue} \
            -num_threads {threads} \
            > ../{output}'

rule run_blastx:
    """
    Run NCBI blastx to search protein database with assembly query.
    """
    input:
        fasta='{assembly}.fasta',
        db='blast/{name}.root.{root}{masked}.pal'
    output:
        '{assembly}.blastx.{name}.root.{root}{masked}.out'
    wildcard_constraints:
        root='\d+',
        masked='.[fm][ulins\d\.]+'
    params:
        db=lambda wc: "%s.root.%s%s" % (wc.name,wc.root,wc.masked),
        evalue=lambda wc:similarity[wc.name]['evalue'],
        max_target_seqs=lambda wc:similarity[wc.name]['max_target_seqs']
    conda:
         '../envs/blast.yaml'
    threads: 32
    resources:
        threads=32
    shell:
        'cd blast && \
        blastx \
            -query ../{input.fasta} \
            -db {params.db} \
            -outfmt "6 qseqid staxids bitscore std" \
            -max_target_seqs {params.max_target_seqs} \
            -max_hsps 1 \
            -evalue {params.evalue} \
            -num_threads {threads} \
            > ../{output}'

rule run_diamond_blastx:
    """
    Run Diamond blastx to search protein database with assembly query.
    """
    input:
        fasta='{assembly}.fasta',
        db='{name}.root.{root}{masked}.dmnd'
    output:
        '{assembly}.diamond.{name}.root.{root}{masked}.out'
    wildcard_constraints:
        root='\d+',
        masked='.[fm][ulins\d\.]+'
    params:
        db=lambda wc: "%s.root.%s%s" % (wc.name,wc.root,wc.masked),
        evalue=lambda wc:similarity[wc.name]['evalue'],
        max_target_seqs=lambda wc:similarity[wc.name]['max_target_seqs']
    conda:
         '../envs/diamond.yaml'
    threads: 32
    resources:
        threads=32
    shell:
        'diamond blastx \
            --query {input.fasta} \
            --db {params.db} \
            --outfmt 6 \
            --sensitive \
            --max-target-seqs {params.max_target_seqs} \
            --evalue {params.evalue} \
            --threads {threads} \
            > {output}'

rule run_blobtools_taxify:
    """
    Add taxonomy information to Diamond similarity search results.
    """
    input:
        dmnd='{assembly}.diamond.{name}.root.{root}{masked}.out',
        split=lambda wc: "%s/split/%s.done" % (similarity[wc.name]['local'],wc.name),
        lists='blast/{name}.root.{root}{masked}.lists'
    output:
        '{assembly}.diamond.{name}.root.{root}{masked}.taxified.out'
    params:
        indir=lambda wc: "%s/split/%s" % (similarity[wc.name]['local'],wc.name),
        idmap=lambda wc: "%s/%s.taxid_map" % (config['settings']['tmp'],wc.name)
    wildcard_constraints:
        root='\d+',
        masked='.[fm][ulins\d\.]+'
    conda:
        '../envs/blobtools.yaml'
    threads: 1
    resources:
        threads=1
    shell:
        'parallel --no-notice -j {threads} \
            "gunzip -c {params.indir}/{{}}.taxid_map.gz" \
            :::: {input.lists} > {params.idmap} && \
        blobtools taxify \
            -f {input.dmnd} \
            -m {params.idmap} \
            -s 0 \
            -t 1 && \
        rm {params.idmap}'
