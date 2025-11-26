.PHONY: help apply apply-all apply-meu-site apply-locust restart-meu-site restart-locust status logs-meu-site logs-locust port-forward-meu-site port-forward-locust clean delete-all

# Default target
help:
	@echo "Comandos disponíveis:"
	@echo "  apply-all          - Aplica todos os manifestos (meu-site e locust)"
	@echo "  apply-meu-site     - Aplica apenas os manifestos do meu-site"
	@echo "  apply-locust       - Aplica apenas os manifestos do locust"
	@echo "  restart-meu-site   - Reinicia o deployment do meu-site"
	@echo "  restart-locust     - Reinicia o deployment do locust"
	@echo "  status             - Mostra o status dos recursos"
	@echo "  logs-meu-site      - Mostra os logs do meu-site"
	@echo "  logs-locust        - Mostra os logs do locust"
	@echo "  port-forward-meu-site - Faz port-forward do meu-site (porta 3000)"
	@echo "  port-forward-locust  - Faz port-forward do locust (porta 8089)"
	@echo "  clean              - Remove os recursos aplicados"
	@echo "  delete-all         - Remove todos os recursos do namespace meu-site"

# Aplicar manifestos
apply-all: apply-meu-site apply-locust

apply-meu-site:
	@echo "Aplicando manifestos do meu-site..."
	@kubectl apply -f meu-site/

apply-locust:
	@echo "Aplicando manifestos do locust..."
	@kubectl apply -f locust/

# Para compatibilidade com o antigo
apply: apply-meu-site

# Reiniciar deployments
restart-meu-site:
	@echo "Reiniciando deployment do meu-site..."
	@kubectl rollout restart deployment/meu-site -n meu-site

restart-locust:
	@echo "Reiniciando deployment do locust..."
	@kubectl rollout restart deployment/locust -n meu-site

# Para compatibilidade
atualizar: restart-meu-site

# Status
status:
	@echo "Pods:"
	@kubectl get pods -n meu-site
	@echo "\nServices:"
	@kubectl get svc -n meu-site
	@echo "\nIngresses:"
	@kubectl get ingress -n meu-site
	@echo "\nDeployments:"
	@kubectl get deployments -n meu-site
	@echo "\nHPA:"
	@kubectl get hpa -n meu-site

# Logs
logs-meu-site:
	@kubectl logs -f deployment/meu-site -n meu-site --tail=100

logs-locust:
	@kubectl logs -f deployment/locust -n meu-site --tail=100

# Port forward
port-forward-meu-site:
	@echo "Fazendo port-forward do meu-site na porta 3000..."
	@kubectl port-forward svc/meu-site 3000:3000 -n meu-site

port-forward-locust:
	@echo "Fazendo port-forward do locust na porta 8089..."
	@kubectl port-forward svc/locust 8089:8089 -n meu-site

# Limpeza
clean: delete-all

delete-all:
	@echo "Removendo todos os recursos do namespace meu-site..."
	@kubectl delete -f meu-site/ --ignore-not-found=true
	@kubectl delete -f locust/ --ignore-not-found=true

cleanup-pvs:
	@echo "🔧 Verificando e liberando PVs..."
	@for pv in meu-site-db-pv; do \
		if kubectl get pv $$pv >/dev/null 2>&1; then \
			STATUS=$$(kubectl get pv $$pv -o jsonpath='{.status.phase}'); \
			if [ "$$STATUS" = "Released" ]; then \
				echo "  🔓 Liberando $$pv..."; \
				kubectl patch pv $$pv --type json -p '[{"op": "remove", "path": "/spec/claimRef"}]' 2>/dev/null || true; \
			fi; \
		fi; \
	done
	@echo "✅ PVs verificados"
	@echo "========================================"