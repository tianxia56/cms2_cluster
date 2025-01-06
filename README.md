# cms2_cluster

run with env: selscan, python3, R

need prepared 

.par file

.recom file

double check cosi image

```apptainer build cosi.sif docker://docker.io/tx56/cosi```

edit ```config.json```
then run ```main_sbatch_array.sh```

update partition and runtime by editing ```zzz-update-runtime.py```
