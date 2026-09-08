#跑在core6上,
sudo cyclictest -a 7 -p 90 -t 1 --mainaffinity=0 -N
#sudo taskset -c 0-4 cyclictest -a 2 -p 90 -t 1 -m --mainaffinity=0 -N
