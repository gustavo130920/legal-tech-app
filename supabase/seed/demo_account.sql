-- Conteúdo da conta de demonstração usada na avaliação do TCC.
-- Textos meramente ilustrativos, sem dados reais de clientes ou processos.
--
-- Uso: troque EMAIL_DA_CONTA_DEMO pelo e-mail da conta já cadastrada no app.
-- O script não roda em conta inexistente nem em conta que já tenha dados.

do $$
declare
  v_email constant text := 'EMAIL_DA_CONTA_DEMO';
  v_user uuid;
  v_ids bigint[];
  v_all bigint[];
begin
  select id into v_user from auth.users where lower(email) = lower(v_email);
  if v_user is null then
    raise exception 'Conta % não encontrada.', v_email;
  end if;

  if exists (select 1 from public.pecas where user_id = v_user)
     or exists (select 1 from public.topics where user_id = v_user) then
    raise exception 'A conta % já tem dados. Nada foi alterado.', v_email;
  end if;

  insert into public.user_areas (user_id, areas)
  values (v_user, array['Trabalhista', 'Civil'])
  on conflict (user_id) do update set areas = excluded.areas;

  -- Trabalhista
  insert into public.pecas (user_id, area_name, peca_name, header_template)
  values (
    v_user, 'Trabalhista', 'CONTESTAÇÃO TRABALHISTA',
    E'EXCELENTÍSSIMO(A) SENHOR(A) DOUTOR(A) JUIZ(A) DO TRABALHO {{ENDEREÇAMENTO}}.\n\nProcesso nº.   {{PROCESSO}}\n\n{{REU}}, por seus advogados e procuradores infra-assinados, nos autos da reclamação trabalhista movida por {{NOME_CLIENTE}}, vem, respeitosamente, à presença de Vossa Excelência, apresentar CONTESTAÇÃO, pelos fatos e fundamentos a seguir.'
  );

  with novos as (
    insert into public.topics (user_id, area_name, peca_name, title, content, preview, variables)
    select v_user, 'Trabalhista', 'CONTESTAÇÃO TRABALHISTA', t.title, t.content,
           case when length(t.content) > 40 then left(t.content, 40) || '...' else t.content end,
           t.variables
    from (values
      (1, 'Da inépcia do pedido',
       E'O pedido formulado não indica de forma certa e determinada o valor pretendido, em desacordo com o art. 840, § 1º, da CLT.\nRequer a extinção do pedido sem resolução do mérito.',
       array[]::text[]),
      (2, 'Das horas extras',
       E'A parte reclamante alega jornada de {{JORNADA_ALEGADA}}, o que não corresponde à realidade.\nOs controles de ponto registram corretamente a jornada cumprida, e eventuais horas extras foram pagas ou compensadas.\nCabe à parte reclamante comprovar o fato constitutivo do direito, nos termos do art. 818, I, da CLT.',
       array['JORNADA_ALEGADA']),
      (3, 'Do intervalo intrajornada',
       E'A parte reclamante usufruiu regularmente do intervalo previsto no art. 71 da CLT, conforme registros de ponto.\nCaso reconhecida a supressão parcial, o pagamento deve se limitar ao período suprimido, nos termos do art. 71, § 4º, da CLT.',
       array[]::text[]),
      (4, 'Das verbas rescisórias',
       E'O contrato vigorou de {{DATA_ADMISSAO}} a {{DATA_DEMISSAO}}, e as verbas rescisórias foram pagas no prazo do art. 477, § 6º, da CLT, conforme termo de rescisão anexo.\nNão há diferenças devidas.',
       array['DATA_ADMISSAO', 'DATA_DEMISSAO']),
      (5, 'Do pedido',
       E'Diante do exposto, requer o acolhimento da preliminar, se for o caso, e a total improcedência dos pedidos.\nProtesta por todos os meios de prova admitidos em direito.',
       array[]::text[])
    ) as t(ordem, title, content, variables)
    order by t.ordem
    returning id, title
  )
  select
    array_agg(id order by id) filter (where title in ('Das horas extras', 'Do intervalo intrajornada', 'Do pedido')),
    array_agg(id order by id)
  into v_ids, v_all
  from novos;

  insert into public.topic_kits (user_id, area_name, peca_name, name, topic_ids)
  values
    (v_user, 'Trabalhista', 'CONTESTAÇÃO TRABALHISTA', 'Jornada de trabalho', v_ids),
    (v_user, 'Trabalhista', 'CONTESTAÇÃO TRABALHISTA', 'Contestação completa', v_all);

  -- Civil
  insert into public.pecas (user_id, area_name, peca_name, header_template)
  values (
    v_user, 'Civil', 'AÇÃO DE INDENIZAÇÃO',
    E'EXCELENTÍSSIMO(A) SENHOR(A) DOUTOR(A) JUIZ(A) DE DIREITO {{ENDEREÇAMENTO}}.\n\n{{NOME_CLIENTE}}, inscrito(a) no CPF sob o nº {{CPF}}, por seus advogados infra-assinados, vem, respeitosamente, à presença de Vossa Excelência, propor AÇÃO DE INDENIZAÇÃO POR DANOS MORAIS em face de {{REU}}, pelos fatos e fundamentos a seguir.'
  );

  with novos as (
    insert into public.topics (user_id, area_name, peca_name, title, content, preview, variables)
    select v_user, 'Civil', 'AÇÃO DE INDENIZAÇÃO', t.title, t.content,
           case when length(t.content) > 40 then left(t.content, 40) || '...' else t.content end,
           t.variables
    from (values
      (1, 'Dos fatos',
       E'Em {{DATA_NEGATIVACAO}}, a parte autora tomou conhecimento da inclusão de seu nome em cadastro de inadimplentes, por débito de R$ {{VALOR_DEBITO}} que desconhece.\nNão há contrato ou relação jurídica que justifique a cobrança.',
       array['DATA_NEGATIVACAO', 'VALOR_DEBITO']),
      (2, 'Da relação de consumo',
       E'A relação entre as partes é de consumo, aplicando-se o Código de Defesa do Consumidor.\nRequer a inversão do ônus da prova, nos termos do art. 6º, VIII, do CDC.',
       array[]::text[]),
      (3, 'Do dano moral',
       E'A inclusão indevida em cadastro de inadimplentes gera o dever de indenizar, nos termos dos arts. 186 e 927 do Código Civil e do art. 14 do CDC.\nRequer a fixação da indenização em R$ {{VALOR_INDENIZACAO}}.',
       array['VALOR_INDENIZACAO']),
      (4, 'Do pedido',
       E'Diante do exposto, requer a declaração de inexistência do débito, a exclusão definitiva do apontamento e a condenação da parte ré ao pagamento da indenização pleiteada.\nDá-se à causa o valor de R$ {{VALOR_CAUSA}}.',
       array['VALOR_CAUSA'])
    ) as t(ordem, title, content, variables)
    order by t.ordem
    returning id
  )
  select array_agg(id order by id) into v_all from novos;

  insert into public.topic_kits (user_id, area_name, peca_name, name, topic_ids)
  values (v_user, 'Civil', 'AÇÃO DE INDENIZAÇÃO', 'Negativação indevida', v_all);
end $$;
