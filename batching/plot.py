import matplotlib.pyplot as plt
import numpy as np
import re
import os

def read_file(fname,model,dryrun):

    col_rank=5
    col_time=8

    f = open(fname,'r')

    ranks=[]
    times=[]

    if (model=='1k'): 
        lines = f.readlines()[1:13]

    elif (model=='10k'):
        lines = f.readlines()[13:25]

    else: 
        print('Wrong cell model!')

    for x in lines:
        alls=re.sub("\s+", ",", x.strip())
        splits=alls.split(",")
        ranks.append(int(splits[col_rank]))
        times.append(float(splits[col_time]))

    f.close()

    return ranks,times

def plot_scaling(x,y,dryrun,model):
   print('ranks= ', x)
   print('times=', y)
   fig = plt.figure()
   plt.semilogx(x, y, basex=2, marker='o', color='k')
   plt.xlabel('ranks')
   plt.ylabel('wall time (s)')
   if (dryrun=='true'):
       plt.title(model+' cells per rank in dryrun mode')
   elif(dryrun=='false'):
       plt.title(model+' cells per rank in real mode')
   else:
        print('Wrong dryrun mode!')
        raise SystemExit()
   ylim_down=float(input('set lower y limit= '))
   ylim_up=float(input('set upper y limit= '))
   plt.ylim(ylim_down,ylim_up)
   plt.grid(True)
   plt.savefig('weak_scaling_ring_small_' + dryrun + '_' + model + '.pdf')

def main():
   fname=input("input file: ")
   model=input("model size (1k/10k): ")
   dryrun=input("dryrun mode (true/false): ")

   ranks,times=read_file(fname,model,dryrun)
   plot_scaling(ranks,times,dryrun,model)

if __name__ == '__main__':
    main()    




