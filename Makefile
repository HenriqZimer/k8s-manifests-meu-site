apply:
	@kubectl apply -f meu-site

atualizar:
	@kubectl rollout restart deployment/meu-site -n meu-site