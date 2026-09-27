-- Papel do time financeiro (contas a pagar, aprovações, contabilidade e painéis).
-- ADD VALUE é aditivo: usuários existentes não mudam.
ALTER TYPE "Role" ADD VALUE IF NOT EXISTS 'financeiro';
