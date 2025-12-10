.PHONY: help apply apply-all apply-meu-site apply-locust apply-meu-site-stack restart-meu-site restart-locust restart-meu-site-stack status logs-meu-site logs-locust logs-meu-site-stack port-forward-meu-site port-forward-locust port-forward-meu-site-stack clean delete-all cleanup-pvs

# Default target
help:
	@echo "Comandos disponíveis:"
	@echo "  apply-all              - Aplica todos os manifestos (meu-site, locust e meu-site-stack)"
	@echo "  apply-meu-site         - Aplica apenas os manifestos do meu-site"
	@echo "  apply-locust           - Aplica apenas os manifestos do locust"
	@echo "  apply-meu-site-stack   - Aplica apenas os manifestos do meu-site-stack"
	@echo "  restart-meu-site       - Reinicia o deployment do meu-site"
	@echo "  restart-locust         - Reinicia o deployment do locust"
	@echo "  restart-meu-site-stack - Reinicia os deployments do meu-site-stack"
	@echo "  status                 - Mostra o status dos recursos"
	@echo "  logs-meu-site          - Mostra os logs do meu-site"
	@echo "  logs-locust            - Mostra os logs do locust"
	@echo "  logs-meu-site-stack    - Mostra os logs do meu-site-stack"
	@echo "  port-forward-meu-site  - Faz port-forward do meu-site (porta 3000)"
	@echo "  port-forward-locust    - Faz port-forward do locust (porta 8089)"
	@echo "  port-forward-meu-site-stack - Faz port-forward do meu-site-stack (porta 80)"
	@echo "  clean                  - Remove os recursos aplicados"
	@echo "  delete-all             - Remove todos os recursos dos namespaces"
	@echo "  cleanup-pvs            - Libera PVs órfãos"

# Aplicar manifestos
apply-all: apply-meu-site apply-locust apply-meu-site-stack

apply-meu-site:
	@echo "Aplicando manifestos do meu-site..."
	@kubectl apply -f meu-site/

apply-locust:
	@echo "Aplicando manifestos do locust..."
	@kubectl apply -f locust/

apply-meu-site-stack:
	@echo "Aplicando manifestos do meu-site-stack..."
	@kubectl apply -f meu-site-stack/

# Para compatibilidade com o antigo
apply: apply-meu-site

# Reiniciar deployments
restart-meu-site:
	@echo "Reiniciando deployment do meu-site..."
	@kubectl rollout restart deployment/meu-site -n meu-site

restart-locust:
	@echo "Reiniciando deployment do locust..."
	@kubectl rollout restart deployment/locust -n meu-site

restart-meu-site-stack:
	@echo "Reiniciando deployments do meu-site-stack..."
	@kubectl rollout restart deployment/meu-site-frontend -n meu-site-stack
	@kubectl rollout restart deployment/meu-site-backend -n meu-site-stack

# Para compatibilidade
atualizar: restart-meu-site

# Status
status:
	@echo "=== Namespace meu-site ==="
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
	@echo "\n=== Namespace meu-site-stack ==="
	@echo "Pods:"
	@kubectl get pods -n meu-site-stack
	@echo "\nServices:"
	@kubectl get svc -n meu-site-stack
	@echo "\nIngresses:"
	@kubectl get ingress -n meu-site-stack
	@echo "\nDeployments:"
	@kubectl get deployments -n meu-site-stack
	@echo "\nHPA:"
	@kubectl get hpa -n meu-site-stack

# Logs
logs-meu-site:
	@kubectl logs -f deployment/meu-site -n meu-site --tail=100

logs-locust:
	@kubectl logs -f deployment/locust -n meu-site --tail=100

logs-meu-site-stack:
	@echo "Escolha o deployment: frontend ou backend"
	@read -p "Digite 'frontend' ou 'backend': " choice; \
	if [ "$$choice" = "frontend" ]; then \
		kubectl logs -f deployment/meu-site-frontend -n meu-site-stack --tail=100; \
	elif [ "$$choice" = "backend" ]; then \
		kubectl logs -f deployment/meu-site-backend -n meu-site-stack --tail=100; \
	else \
		echo "Opção inválida"; \
	fi

# Port forward
port-forward-meu-site:
	@echo "Fazendo port-forward do meu-site na porta 3000..."
	@kubectl port-forward svc/meu-site 3000:3000 -n meu-site

port-forward-locust:
	@echo "Fazendo port-forward do locust na porta 8089..."
	@kubectl port-forward svc/locust 8089:8089 -n meu-site

port-forward-meu-site-stack:
	@echo "Fazendo port-forward do meu-site-stack na porta 8080..."
	@kubectl port-forward svc/meu-site-frontend 8080:80 -n meu-site-stack

# Limpeza
clean: delete-all

delete-all:
	@echo "Removendo todos os recursos do namespace meu-site..."
	@kubectl delete -f meu-site/ --ignore-not-found=true
	@kubectl delete -f locust/ --ignore-not-found=true
	@echo "Removendo todos os recursos do namespace meu-site-stack..."
	@kubectl delete -f meu-site-stack/ --ignore-not-found=true

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