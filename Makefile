#please do this in an virtual environment
cudaPNRR.png: figCuda.py Aug08_13-11_cuda/cudacoord/.gitignore
	@pip install -r requirements.txt
	@python figCuda.py

Aug08_13-11_cuda/cudacoord/.gitignore: Aug08_13-11_cuda.tar.gz
	@tar -xvf Aug08_13-11_cuda.tar.gz
	@touch $@

