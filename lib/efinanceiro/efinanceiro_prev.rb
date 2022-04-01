class EFinaceiroPrev
    ###### CONSTANTES #######################################################################################################################
    ##### HOMOLOG
    URL_HOMOLOG             = 'https://preprod-efinanc.receita.fazenda.gov.br/WsEFinanceiraCripto/WsRecepcaoCripto.asmx?wsdl'
    URL_CONSULTA_HOMOLOG    = 'https://preprod-efinanc.receita.fazenda.gov.br/WsEFinanceira/WsConsulta.asmx?wsdl'
    CERT_SERVER_HOMOLOG     = 'lib/efinanceiro/certificados/ecpf_atila/preprod-efinancentreposto.receita.fazenda.gov.br.cer'
    ID_CERTIFICATE_HOMOLG   = '88EDFFA74BF7984197C1749BA96F56372DC02BAC'
    ##### PROD
    URL_PROD                = 'https://efinanc.receita.fazenda.gov.br/WsEFinanceiraCripto/WsRecepcaoCripto.asmx?wsdl'
    URL_CONSULTA_PROD       = 'https://efinanc.receita.fazenda.gov.br/WsEFinanceira/WsConsulta.asmx?wsdl'
    CERT_SERVER_PROD        = 'lib/efinanceiro/certificados/ecpf_atila/efinanc_web.cer'
    ID_CERTIFICATE_PROD     = '95e2ee3134b418f8319be1b9fc38d0b654bbae42'
    #####
    NS                      = 'http://sped.fazenda.gov.br/'
    CERT_CLIENT             = 'lib/efinanceiro/certificados/ecpf_atila/cert.pem'
    KEY                     = 'lib/efinanceiro/certificados/ecpf_atila/key.pem'
    PASSWORD                = '82558237'
    CERTIFICATE             =  OpenSSL::PKCS12.new(File.read(Dir.glob('lib/efinanceiro/certificados/ecpf_atila/*.pfx').first), PASSWORD)
    NAMESPACES_STANDARDS    = {'xmlns:xsd'=>'http://www.w3.org/2001/XMLSchema', 'xmlns:xsi'=>'http://www.w3.org/2001/XMLSchema-instance'}
    ######## VARIAVEIS GLOBAIS ##############################################################################################################
    HTTPI.adapter = :net_http

    @@CERT_SERVER
    @@ID_CERTIFICATE
    @@URL_CONS
    @@URL
    ################################# MÉTODOS ################################
    def self.web_service(amb, xml)
        amb.eql?('producao') ? @@URL = URL_PROD : @@URL = URL_HOMOLOG

        client = Savon::Client.new(
            namespace_identifier: :sped,
            wsdl: @@URL,
            namespace: NS,
            ssl_cert_file: CERT_CLIENT,
            ssl_cert_key_file: KEY,
            endpoint: @@URL,
            ssl_verify_mode: :none,
            ssl_version: :TLSv1_2,
            ######## DEBUG #########
            # ssl_verify_mode: :none,
            # log: true,
            # pretty_print_xml: true,
            # log_level: :debug
        )

        # OBS: Parâmetros do método call do client do savon
        # message => só conteúdo do corpo do xml na chamada, as tags soap são colocadas automaticamente.
        # xml     => arquivo xml completo na chamada.
        response = client.call(:receber_lote_evento_cripto_g_zip, message: xml, advanced_typecasting: false)

        return response
    end

    def self.web_service_consulta(action, cnpj_declarante, *args)
        args.last.to_i == 1 ? @@URL_CONS = URL_CONSULTA_PROD : @@URL_CONS = URL_CONSULTA_HOMOLOG

        client = Savon::Client.new(
            wsdl: @@URL_CONS,
            namespace: NS,
            ssl_cert_file: CERT_CLIENT,
            ssl_cert_key_file: KEY,
            endpoint: @@URL_CONS,
            ssl_verify_mode: :none,
            ssl_version: :TLSv1_2,
            ######## DEBUG #########
            # log: true,
            # pretty_print_xml: true,
            # log_level: :debug
        )

        case action
        when 'consultar_informacoes_cadastrais'
            response = client.call(:consultar_informacoes_cadastrais) do
                message cnpj: "#{cnpj_declarante}"
                advanced_typecasting :false
            end
        when 'consultar_informacoes_movimento'
           response = client.call(:consultar_informacoes_movimento) do
              message cnpj: "#{cnpj_declarante}", situacaoInformacao: "#{args[0]}", anoMesInicioVigencia: "#{args[1].to_date.strftime("%Y%m").to_s}", anoMesTerminoVigencia: "#{args[2].to_date.strftime("%Y%m").to_s}", tipoMovimento: "#{args[3]}", tipoIdentificacao: "#{args[4]}", identificacao: "#{args[5]}"
              advanced_typecasting :false
           end
        when 'consultar_lista_eFinanceira'
            response = client.call(:consultar_lista_e_financeira) do
                message cnpj: "#{cnpj_declarante}", situacaoEFinanceira: "#{args[0]}", dataInicio: "#{args[1].to_date.strftime("%Y-%m-%d").to_s}", dataFim: "#{args[2].to_date.strftime("%Y-%m-%d").to_s}"
                advanced_typecasting :false
            end
        else
           ####### IMPLEMENT  #######
        end

        return response
    end

    def self.atualizar_movimento(movimento, node, xmlRetorno)
        movimento.update_column(:arquivo_retorno, xmlRetorno)
        movimento.update_column(:data_arquivo_retorno, Time.zone.now)
        movimento.update_column(:nr_recibo, node.at_css('retornoEvento/dadosReciboEntrega/numeroRecibo').text)
    end

    def self.xml_retorno(xmlRetorno, movimento)
        node = Nokogiri::XML(xmlRetorno)
        node.remove_namespaces!

        if node.at_css('retornoEvento/status/cdRetorno').text.eql?('0')
            atualizar_movimento(movimento, node, xmlRetorno)
            return 'Envio de lote enviado com sucesso, e disponibilizado para download.', :success
        elsif node.at_css('retornoEventos/evento/eFinanceira/retornoEvento/status/dadosRegistroOcorrenciaEvento/ocorrencias/codigo').text.eql?('MS0022')
            if movimento.arquivo_retorno.nil?
                atualizar_movimento(movimento, node, xmlRetorno)
                return 'Número Recibo do lote atualizado.', :success
            else
                ####### IMPLEMENT  #######
            end
        else
            return "Código: #{node.at_css("retornoEventos/evento/eFinanceira/retornoEvento/status/dadosRegistroOcorrenciaEvento/ocorrencias/codigo").text}, #{node.at_css("retornoEventos/evento/eFinanceira/retornoEvento/status/dadosRegistroOcorrenciaEvento/ocorrencias/descricao").text}", :error
        end
    end

    def self.xml_completo(xmlAssinado)
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.eFinanceira(NAMESPACES_STANDARDS, 'xmlns'=>'http://www.eFinanceira.gov.br/schemas/envioLoteEventos/v1_2_0') {
                xml.loteEventos { xml.evento('id'=> 'ID0') }
            }
        end

        doc = builder.to_xml
        xml = Nokogiri::XML(doc)
        xml.at('evento').add_child(xmlAssinado)

        return xml.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
    end

    def self.cadastro_declarante(dados, movimento)
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.eFinanceira('xmlns'=>'http://www.eFinanceira.gov.br/schemas/evtCadDeclarante/v1_2_0') {
                xml.evtCadDeclarante('id'=> "#{dados[2]}") {
                    xml.ideEvento {
                        xml.indRetificacao "#{dados[3]}"
                        xml.tpAmb "#{dados[4]}"
                        xml.aplicEmi "#{dados[5]}"
                        xml.verAplic "#{dados[6]}"
                    }

                    xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }

                    xml.infoCadastro {
                        xml.nome "#{dados[8]}"
                        xml.enderecoLivre "#{dados[9]}"
                        xml.municipio "#{dados[10]}"
                        xml.UF "#{dados[11]}"
                        xml.Pais "#{dados[12]}"
                        xml.paisResidencia "#{dados[13]}"
                    }
                }
            }
        end

        body_xml = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        xml_assinado = assinar(body_xml, 'evtCadDeclarante', CERTIFICATE)
        xml_cad_declarante = xml_completo(xml_assinado)
        xml_encrypted = criptografia_lote_efinanceira(xml_cad_declarante, movimento.tipo_ambiente)

        begin
            response = web_service(movimento.tipo_ambiente, xml_encrypted)

            if response.success?
                msg, status = xml_retorno(response.xml, movimento)
                return  msg, status
            else
                return 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
            end

        rescue Exception => e
            return '', "#{e.message}", :error
        end
    end

    def self.abertura_efinanceira(dados, movimento)
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.eFinanceira('xmlns'=>'http://www.eFinanceira.gov.br/schemas/evtAberturaeFinanceira/v1_2_0') {
                xml.evtAberturaeFinanceira('id'=> "#{dados[2]}") {
                    xml.ideEvento {
                        xml.indRetificacao "#{dados[3]}"
                        xml.tpAmb "#{dados[4]}"
                        xml.aplicEmi "#{dados[5]}"
                        xml.verAplic "#{dados[6]}"
                    }

                    xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }

                    xml.infoAbertura {
                        xml.dtInicio "#{dados[8]}"
                        xml.dtFim "#{dados[9]}"
                    }

                    xml.AberturaMovOpFin {
                        xml.ResponsavelRMF {
                            xml.CPF "#{dados[10].gsub(/[^0-9]/, '').rjust(11, "0")}"
                            xml.Nome "#{dados[11]}"
                            xml.Setor "#{dados[12]}"
                            xml.Telefone {
                                xml.DDD "#{dados[13]}"
                                xml.Numero "#{dados[14]}"
                            }

                            xml.Endereco {
                                xml.Logradouro "#{dados[15]}"
                                xml.Numero "#{dados[16]}"
                                xml.Bairro "#{dados[17]}"
                                xml.CEP "#{dados[18]}"
                                xml.Municipio "#{dados[19]}"
                                xml.UF "#{dados[20]}"
                            }
                        }

                        xml.RespeFin {
                            xml.CPF "#{dados[10].gsub(/[^0-9]/, '').rjust(11, "0")}"
                            xml.Nome "#{dados[11]}"
                            xml.Setor "#{dados[12]}"
                            xml.Telefone {
                                xml.DDD "#{dados[13]}"
                                xml.Numero "#{dados[14]}"
                            }

                            xml.Endereco {
                                xml.Logradouro "#{dados[15]}"
                                xml.Numero "#{dados[16]}"
                                xml.Bairro "#{dados[17]}"
                                xml.CEP "#{dados[18]}"
                                xml.Municipio "#{dados[19]}"
                                xml.UF "#{dados[20]}"
                            }
                                xml.Email "cageprev@cageprev.com.br"
                        }

                        xml.RepresLegal {
                            xml.CPF "#{dados[21].gsub(/[^0-9]/, '').rjust(11, "0")}"
                            xml.Setor "#{dados[22]}"
                            xml.Telefone {
                                xml.DDD "#{dados[23]}"
                                xml.Numero "#{dados[24]}"
                            }
                        }
                    }
                }
            }
        end

        body_xml = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        xml_assinado = assinar(body_xml, 'evtAberturaeFinanceira', CERTIFICATE)
        xml_abertura = xml_completo(xml_assinado)
        xml_encrypted = criptografia_lote_efinanceira(xml_abertura, movimento.tipo_ambiente)

        begin
            response = web_service(movimento.tipo_ambiente, xml_encrypted)

            if response.success?
                msg, status = xml_retorno(response.xml, movimento)
                return  msg, status
            else
                return 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
            end
        rescue Exception => e
            return '', "#{e.message}", :error
        end
    end

    def self.movimento_operacao_financeira(dados, movimento)
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.eFinanceira('xmlns'=>'http://www.eFinanceira.gov.br/schemas/evtMovOpFin/v1_2_0') {
                xml.evtMovOpFin('id'=> "#{dados[2]}") {
                    xml.ideEvento {
                        xml.indRetificacao "#{dados[3]}"
                        xml.tpAmb "#{dados[4]}"
                        xml.aplicEmi "#{dados[5]}"
                        xml.verAplic "#{dados[6]}"
                    }

                    xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }

                    xml.ideDeclarado {
                        xml.tpNI "#{dados[8]}"
                        xml.NIDeclarado "#{dados[9].gsub(/[^0-9]/, '').rjust(11, "0")}"
                        xml.NomeDeclarado "#{dados[10]}"
                        xml.EnderecoLivre "#{dados[11]}"
                        xml.PaisEndereco { xml.Pais "#{dados[12]}" }
                    }

                    xml.mesCaixa {
                        xml.anoMesCaixa "#{dados[13]}"
                        xml.movOpFin {
                            xml.Conta {
                                xml.infoConta {
                                    xml.Reportavel { xml.Pais "#{dados[14]}" }
                                    xml.tpConta "#{dados[15]}"
                                    xml.subTpConta "#{dados[16]}"
                                    xml.tpNumConta "#{dados[17]}"
                                    xml.numConta "#{dados[18]}"
                                    xml.tpRelacaoDeclarado "#{dados[19]}"
                                    xml.NoTitulares "#{dados[20]}"

                                    if dados[21].index(",").present?
                                        xml.BalancoConta {
                                            xml.totCreditos "#{dados[21]}"
                                            xml.totDebitos "#{dados[22]}"
                                            xml.totCreditosMesmaTitularidade "#{dados[23]}"
                                            xml.totDebitosMesmaTitularidade "#{dados[24]}"
                                            xml.vlrUltDia "#{dados[25]}"
                                        }

                                        xml.PgtosAcum {
                                            xml.tpPgto "#{dados[26]}"
                                            xml.totPgtosAcum "#{dados[27]}"
                                        }
                                    else
                                        xml.dtEncerramentoConta "#{dados[21]}"
                                        xml.BalancoConta {
                                            xml.totCreditos "#{dados[22]}"
                                            xml.totDebitos "#{dados[23]}"
                                            xml.totCreditosMesmaTitularidade "#{dados[24]}"
                                            xml.totDebitosMesmaTitularidade "#{dados[25]}"
                                            xml.vlrUltDia "#{dados[26]}"
                                        }

                                        xml.PgtosAcum {
                                            xml.tpPgto "#{dados[27]}"
                                            xml.totPgtosAcum "#{dados[28]}"
                                        }
                                    end
                                }
                            }
                        }
                    }
                }
            }
        end

        body_xml = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        xml_assinado = assinar(body_xml, 'evtMovOpFin', CERTIFICATE)
        xml_mov_financeira = xml_completo(xml_assinado)
        xml_encrypted = criptografia_lote_efinanceira(xml_mov_financeira, movimento.tipo_ambiente)

        begin
            response = web_service(movimento.tipo_ambiente, xml_encrypted)

            if response.success?
                msg, status = xml_retorno(response.xml, movimento)
                return  msg, status
            else
                return 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
            end
        rescue Exception => e
            return '', "#{e.message}", :error
        end
    end

    def self.fechamento_financeira(dados, movimento, fechamento_meses)
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.eFinanceira('xmlns'=>'http://www.eFinanceira.gov.br/schemas/evtFechamentoeFinanceira/v1_2_1') {
                xml.evtFechamentoeFinanceira("id"=> "#{dados[2]}") {
                    xml.ideEvento {
                        xml.indRetificacao "#{dados[3]}"
                        xml.tpAmb "#{dados[4]}"
                        xml.aplicEmi "#{dados[5]}"
                        xml.verAplic "#{dados[6]}"
                    }

                    xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }

                    xml.infoFechamento {
                        xml.dtInicio "#{dados[8]}"
                        xml.dtFim "#{dados[9]}"
                        xml.sitEspecial "#{dados[10]}"
                    }

                    # Meses referente ao período acima.
                    # ---------------------------------
                    xml.FechamentoMovOpFin {
                        fechamento_meses.each do |x, y|
                            xml.FechamentoMes {
                                xml.anoMesCaixa "#{x}"
                                xml.quantArqTrans "#{y}"
                            }
                        end
                    }
                }
            }
        end

        body_xml = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        xml_assinado = assinar(body_xml, 'evtFechamentoeFinanceira', CERTIFICATE)
        xml_fechamento_financeira = xml_completo(xml_assinado)
        xml_encrypted = criptografia_lote_efinanceira(xml_fechamento_financeira, movimento.tipo_ambiente)

        begin
            response = web_service(movimento.tipo_ambiente, xml_encrypted)

            if response.success?
                msg, status = xml_retorno(response.xml, movimento)
                return  msg, status
            else
                return 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
            end
        rescue Exception => e
            return '', "#{e.message}", :error
        end
    end

    ## Mata tudo e joga uma pá de cal
    # --------------------------------
    def self.exlcusao(dados, movimento)
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.eFinanceira('xmlns'=>'http://www.eFinanceira.gov.br/schemas/evtExclusao/v1_2_0') {
                xml.evtExclusao('id'=> "#{dados[2]}") {
                    xml.ideEvento {
                        xml.tpAmb "#{dados[4]}"
                        xml.aplicEmi "#{dados[5]}"
                        xml.verAplic "#{dados[6]}"
                    }

                    xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }
                    xml.infoExclusao { xml.nrReciboEvento "#{dados[8]}" }
                }
            }
        end

        body_xml = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        xml_assinado = assinar(body_xml, 'evtExclusao', CERTIFICATE)
        xml_exclusao = xml_completo(xml_assinado)
        xml_encrypted = criptografia_lote_efinanceira(xml_exclusao, movimento.tipo_ambiente)

        begin
            response = web_service(movimento.tipo_ambiente, xml_encrypted)

            if response.success?
                msg, status = xml_retorno(response.xml, movimento)
                return  msg, status
            else
                return 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
            end
        rescue Exception => e
            return '', "#{e.message}", :error
        end
    end

    def self.exlcusao_financeira(dados, movimento)
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.eFinanceira('xmlns'=>'http://www.eFinanceira.gov.br/schemas/evtExclusaoeFinanceira/v1_0_1') {
                xml.evtExclusaoeFinanceira('id'=> "#{dados[2]}") {
                    xml.ideEvento {
                        xml.tpAmb "#{dados[3]}"
                        xml.aplicEmi "#{dados[4]}"
                        xml.verAplic "#{dados[5]}"
                    }

                    xml.ideDeclarante { xml.cnpjDeclarante "#{dados[6]}" }
                    xml.infoExclusao { xml.nrReciboEvento "#{dados[7]}" }
                }
            }
        end

        body_xml = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        xml_assinado = assinar(body_xml, 'evtExclusaoeFinanceira', CERTIFICATE)
        xml_exclusao_financeiro = xml_completo(xml_assinado)
        xml_encrypted = criptografia_lote_efinanceira(xml_exclusao_financeiro, movimento.tipo_ambiente)

        begin
            response = web_service(movimento.tipo_ambiente, xml_encrypted)

            if response.success?
                msg, status = xml_retorno(response.xml, movimento)
                return  msg, status
            else
                return 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
            end
        rescue Exception => e
            return '', "#{e.message}", :error
        end
    end

    # Assina o xml para envio do evento de lote assinado
    # --------------------------------------------------
    def self.assinar(xml, assinar_tag, certificado)
        # xml = strip_xml(xml)
        xml = Nokogiri::XML(xml, &:noblanks)
        content_sign = xml.at_css(assinar_tag)
        id_sign = content_sign['id']

        # 1. Digest Hash for all XML
        xml_canon = content_sign.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
        xml_digest = Base64.encode64(OpenSSL::Digest::SHA256.digest(xml_canon)).strip

        # 2. Add Signature Node
        signature = xml.css('Signature').first
        unless signature
            signature = Nokogiri::XML::Node.new('Signature', xml)
            signature.default_namespace = 'http://www.w3.org/2000/09/xmldsig#'
            xml.root().add_child(signature)
        end

        # 3. Add Elements to Signature Node

        # 3.1 Create Signature Info
        signature_info = Nokogiri::XML::Node.new('SignedInfo', xml)

        # 3.2 Add CanonicalizationMethod
        child_node = Nokogiri::XML::Node.new('CanonicalizationMethod', xml)
        # child_node['Algorithm'] = 'http://www.w3.org/2001/10/xml-exc-c14n#'
        child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
        signature_info.add_child child_node

        # 3.3 Add SignatureMethod
        child_node = Nokogiri::XML::Node.new('SignatureMethod', xml)
        child_node['Algorithm'] = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
        signature_info.add_child child_node

        # 3.4 Create Reference
        reference = Nokogiri::XML::Node.new('Reference', xml)
        reference['URI'] = "##{id_sign}"

        # 3.5 Add Transforms
        transforms = Nokogiri::XML::Node.new('Transforms', xml)

        child_node  = Nokogiri::XML::Node.new('Transform', xml)
        child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature'
        transforms.add_child child_node

        child_node  = Nokogiri::XML::Node.new('Transform', xml)
        child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
        transforms.add_child child_node

        reference.add_child transforms

        # 3.6 Add Digest
        child_node  = Nokogiri::XML::Node.new('DigestMethod', xml)
        child_node['Algorithm'] = 'http://www.w3.org/2001/04/xmlenc#sha256'
        reference.add_child child_node

        # 3.6 Add DigestValue
        child_node  = Nokogiri::XML::Node.new('DigestValue', xml)
        child_node.content = xml_digest
        reference.add_child child_node

        # 3.7 Add Reference and Signature Info
        signature_info.add_child reference
        signature.add_child signature_info

        # 4 Sign Signature
        sign_canon = signature_info.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
        signature_hash = certificado.key.sign(OpenSSL::Digest::SHA256.new, sign_canon)
        signature_value = Base64.encode64(signature_hash).gsub("\n", '')

        # 4.1 Add SignatureValue
        child_node = Nokogiri::XML::Node.new('SignatureValue', xml)
        child_node.content = signature_value
        signature.add_child child_node

        # 5 Create KeyInfo
        key_info = Nokogiri::XML::Node.new('KeyInfo', xml)

        # 5.1 Add X509 Data and Certificate
        x509_data = Nokogiri::XML::Node.new('X509Data', xml)
        x509_certificate = Nokogiri::XML::Node.new('X509Certificate', xml)
        x509_certificate.content = certificado.certificate.to_s.gsub(/\-\-\-\-\-[A-Z]+ CERTIFICATE\-\-\-\-\-/, "").gsub(/\n/,"")

        x509_data.add_child x509_certificate
        key_info.add_child x509_data

        # 5.2 Add KeyInfo
        signature.add_child key_info

        # 6 Add Signature
        xml.root().add_child signature

        # Return XML
        xml.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
    end

    def self.importar_txt(arquivo, user_id, file_name)
        accepted_formats = ['.txt']
        if accepted_formats.include? File.extname(file_name)
            msg, status = validar_txt(arquivo, user_id)
            if status == :success
                File.read(arquivo, :encoding => 'UTF-8').each_line do |line|
                    if line.presence
                        movimento = Movimento.new
                        movimento.arquivo_origem = line
                        evento = line.split(';')
                        xml_template = XmlTemplate.find_by(evento: evento[1])
                        movimento.xml_template_id = xml_template.id
                        movimento.user_id = user_id
                        empresa = Empresa.find_by(cpf_cnpj: evento[7])
                        movimento.empresa_id = empresa.id
                        movimento.tipo_ambiente = evento[4].to_i
                        movimento.save
                    else
                        ####### IMPLEMENT  #######
                    end
                end
                return 'Arquivo importado com sucesso', :success
            else
                return msg, status
            end
        else
            return 'Arquivo com formato inválido!', :error
        end
    end

    # Validar arquivo txt de importação se contém o evento, empresa e permissões a essa empresa.
    # ------------------------------------------------------------------------------------------
    def self.validar_txt(arquivo, user_id)
        File.read(arquivo, :encoding => 'iso-8859-1').each_line do |line|
            if line.presence
                evento = line.split(';')

                xml_template = XmlTemplate.find_by(evento: evento[1])
                unless xml_template
                    return "Importação INVÁLIDA, Evento: #{evento[1]}, não possui casdastro no sistema, providencie junto ao Adm o cadastro do mesmo, importação CANCELADA.", :error
                end

                empresa = Empresa.find_by(cpf_cnpj: evento[7])
                unless empresa
                    return "Importação INVÁLIDA, Empresa: #{evento[7]}, não possui casdastro no sistema, providencie junto ao Adm o cadastro do mesmo, importação CANCELADA.", :error
                end

                empresas = Empresa.joins(:usuario_empresas).where('usuario_empresas.user_id = ?', user_id).map{ |f| f.cpf_cnpj }
                if empresas.select { |array| array == evento[7] }.blank?
                    user = User.find(user_id).email
                    return "Importação INVÁLIDA, Usuário: #{user}, não possui permissão para a Empresa: #{evento[8]}, no sistema, providencie junto ao Adm as permissões necessárias, importação CANCELADA.", :error
                else
                    ####### IMPLEMENT  #######
                end
            else
                ####### IMPLEMENT  #######
            end
        end
        return '', :success
    end

    def self.xml_envio(id_movimento)
        movimento = Movimento.find(id_movimento)
        dados = movimento.arquivo_origem.split(';')

        case dados[1]
        when 'evtCadDeclarante'
            builder = Nokogiri::XML::Builder.new do |xml|
                xml.eFinanceira {
                    xml.evtCadDeclarante('id'=> "#{dados[2]}") {
                        xml.ideEvento {
                            xml.indRetificacao "#{dados[3]}"
                            xml.tpAmb "#{dados[4]}"
                            xml.aplicEmi "#{dados[5]}"
                            xml.verAplic "#{dados[6]}"
                        }

                        xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }

                        xml.infoCadastro {
                            xml.nome "#{dados[8]}"
                            xml.enderecoLivre "#{dados[9]}"
                            xml.municipio "#{dados[10]}"
                            xml.UF "#{dados[11]}"
                            xml.Pais "#{dados[12]}"
                            xml.paisResidencia "#{dados[13]}"
                        }
                    }
                }
            end

            conteudo = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
            return conteudo, 'evtCadDeclarante'
        when 'evtAberturaeFinanceira'
            builder = Nokogiri::XML::Builder.new do |xml|
                xml.eFinanceira('xmlns'=>'http://www.eFinanceira.gov.br/schemas/evtAberturaeFinanceira/v1_2_0') {
                    xml.evtAberturaeFinanceira('id'=> "#{dados[2]}") {
                        xml.ideEvento {
                            xml.indRetificacao "#{dados[3]}"
                            xml.tpAmb "#{dados[4]}"
                            xml.aplicEmi "#{dados[5]}"
                            xml.verAplic "#{dados[6]}"
                        }

                        xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }

                        xml.infoAbertura {
                            xml.dtInicio "#{dados[8]}"
                            xml.dtFim "#{dados[9]}"
                        }

                        xml.AberturaMovOpFin {
                            xml.ResponsavelRMF {
                                xml.CPF "#{dados[10].gsub(/[^0-9]/, '').rjust(11, '0')}"
                                xml.Nome "#{dados[11]}"
                                xml.Setor "#{dados[12]}"
                                xml.Telefone {
                                    xml.DDD "#{dados[13]}"
                                    xml.Numero "#{dados[14]}"
                                }

                                xml.Endereco {
                                    xml.Logradouro "#{dados[15]}"
                                    xml.Numero "#{dados[16]}"
                                    xml.Bairro "#{dados[17]}"
                                    xml.CEP "#{dados[18]}"
                                    xml.Municipio "#{dados[19]}"
                                    xml.UF "#{dados[20]}"
                                }
                            }

                            xml.RespeFin {
                                xml.CPF "#{dados[10].gsub(/[^0-9]/, '').rjust(11, '0')}"
                                xml.Nome "#{dados[11]}"
                                xml.Setor "#{dados[12]}"
                                xml.Telefone {
                                    xml.DDD "#{dados[13]}"
                                    xml.Numero "#{dados[14]}"
                                }

                                xml.Endereco {
                                    xml.Logradouro "#{dados[15]}"
                                    xml.Numero "#{dados[16]}"
                                    xml.Bairro "#{dados[17]}"
                                    xml.CEP "#{dados[18]}"
                                    xml.Municipio "#{dados[19]}"
                                    xml.UF "#{dados[20]}"
                                }
                                    xml.Email "cageprev@cageprev.com.br"
                            }

                            xml.RepresLegal {
                                xml.CPF "#{dados[21].gsub(/[^0-9]/, '').rjust(11, '0')}"
                                xml.Setor "#{dados[22]}"
                                xml.Telefone {
                                    xml.DDD "#{dados[23]}"
                                    xml.Numero "#{dados[24]}"
                                }
                            }
                        }
                    }
                }
            end

            conteudo = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
            return conteudo, 'evtAberturaeFinanceira'
        when 'evtMovOpFin'
            builder = Nokogiri::XML::Builder.new do |xml|
                xml.eFinanceira {
                    xml.evtMovOpFin('id'=> "#{dados[2]}") {
                        xml.ideEvento {
                            xml.indRetificacao "#{dados[3]}"
                            xml.tpAmb "#{dados[4]}"
                            xml.aplicEmi "#{dados[5]}"
                            xml.verAplic "#{dados[6]}"
                        }

                        xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }

                        xml.ideDeclarado {
                            xml.tpNI "#{dados[8]}"
                            xml.NIDeclarado "#{dados[9].gsub(/[^0-9]/, '').rjust(11, "0")}"
                            xml.NomeDeclarado "#{dados[10]}"
                            xml.EnderecoLivre "#{dados[11]}"

                            xml.PaisEndereco { xml.Pais "#{dados[12]}" }
                        }

                        xml.mesCaixa {
                            xml.anoMesCaixa "#{dados[13]}"
                            xml.movOpFin {
                                xml.Conta {
                                    xml.infoConta {
                                        xml.Reportavel { xml.Pais "#{dados[14]}" }
                                        xml.tpConta "#{dados[15]}"
                                        xml.subTpConta "#{dados[16]}"
                                        xml.tpNumConta "#{dados[17]}"
                                        xml.numConta "#{dados[18]}"
                                        xml.tpRelacaoDeclarado "#{dados[19]}"
                                        xml.NoTitulares "#{dados[20]}"

                                        if dados[21].index(",").present?
                                            xml.BalancoConta {
                                                xml.totCreditos "#{dados[21]}"
                                                xml.totDebitos "#{dados[22]}"
                                                xml.totCreditosMesmaTitularidade "#{dados[23]}"
                                                xml.totDebitosMesmaTitularidade "#{dados[24]}"
                                                xml.vlrUltDia "#{dados[25]}"
                                            }

                                            xml.PgtosAcum {
                                                xml.tpPgto "#{dados[26]}"
                                                xml.totPgtosAcum "#{dados[27]}"
                                            }
                                        else
                                            xml.dtEncerramentoConta "#{dados[21]}"
                                            xml.BalancoConta {
                                                xml.totCreditos "#{dados[22]}"
                                                xml.totDebitos "#{dados[23]}"
                                                xml.totCreditosMesmaTitularidade "#{dados[24]}"
                                                xml.totDebitosMesmaTitularidade "#{dados[25]}"
                                                xml.vlrUltDia "#{dados[26]}"
                                            }

                                            xml.PgtosAcum {
                                                xml.tpPgto "#{dados[27]}"
                                                xml.totPgtosAcum "#{dados[28]}"
                                            }
                                        end
                                    }
                                }
                            }
                        }
                    }
                }
            end
            conteudo = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
            return conteudo, 'evtMovOpFin'
        when 'evtExclusao'
            builder = Nokogiri::XML::Builder.new do |xml|
                xml.eFinanceira {
                    xml.evtExclusao('id'=> "#{dados[2]}") {
                        xml.ideEvento {
                            xml.tpAmb "#{dados[4]}"
                            xml.aplicEmi "#{dados[5]}"
                            xml.verAplic "#{dados[6]}"
                        }

                        xml.ideDeclarante { xml.cnpjDeclarante "#{dados[7]}" }
                        xml.infoExclusao { xml.nrReciboEvento "#{dados[8]}" }
                    }
                }
            end
            conteudo = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
            return conteudo, 'evtExclusao'
        when 'evtFechamentoeFinanceira'
            # Removendo sujeira do enter "\r\n"
            remove_enter = dados[dados.length - 1]

            if remove_enter.eql?("\r\n") or remove_enter.eql?("\n")
                # binding.pry
                dados.delete(remove_enter)
            end

            aux = dados[11..dados.length - 1]

            # Quebrando o array em grupos
            numero_de_grupos = aux.count / 2
            fechamento_meses = aux.in_groups(numero_de_grupos)

            builder = Nokogiri::XML::Builder.new do |xml|
                xml.eFinanceira{
                    xml.evtFechamentoeFinanceira('id'=> "#{dados[2]}") {
                        xml.ideEvento {
                            xml.indRetificacao "#{dados[3]}"
                            xml.tpAmb "#{dados[4]}"
                            xml.aplicEmi "#{dados[5]}"
                            xml.verAplic "#{dados[6]}"
                        }

                        xml.ideDeclarante {
                        xml.cnpjDeclarante "#{dados[7]}"
                    }

                    xml.infoFechamento {
                        xml.dtInicio "#{dados[8]}"
                        xml.dtFim "#{dados[9]}"
                        xml.sitEspecial "#{dados[10]}"
                    }

                    # Meses referente ao período acima.
                    # ---------------------------------
                    xml.FechamentoMovOpFin {
                        xml.ReportavelExterior {
                            xml.pais 'US'
                            xml.reportavel 0
                        }

                        fechamento_meses.each do |x, y|
                            xml.FechamentoMes {
                                xml.anoMesCaixa "#{x}"
                                xml.quantArqTrans "#{y}"
                            }
                        end
                    }
                }
            }
         end
            conteudo = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
            return conteudo, 'evtFechamentoeFinanceira'
        end
    end

    def self.consultas(action, cnpj_declarante, *args)
        empresa = Empresa.find_by(cpf_cnpj: "#{cnpj_declarante}")

        if empresa.presence
            case action
            when 'consultar_informacoes_cadastrais'
                begin
                    response = web_service_consulta(action, cnpj_declarante, *args)

                    if response.success?
                        node = Nokogiri::XML(response.xml)
                        node.remove_namespaces!
                        dados = Hash.new

                        # Verifica se existe o nó no XML de retorno
                        # ==========================================
                        if node.at_css('ConsultarInformacoesCadastraisResult')
                            if node.at_css('retornoConsultaInformacoesCadastrais/status/cdRetorno').text.eql?('0')
                                dados[:cnpj] = node.at_css('identificacaoEmpresaDeclarante/cnpjEmpresaDeclarante').text
                                dados[:nome] = node.at_css('retornoConsultaInformacoesCadastrais/informacoesCadastrais/nome').text
                                dados[:endereco] = node.at_css('retornoConsultaInformacoesCadastrais/informacoesCadastrais/endereco').text
                                dados[:municipio] = node.at_css('retornoConsultaInformacoesCadastrais/informacoesCadastrais/municipio').text
                                dados[:uf] = node.at_css('retornoConsultaInformacoesCadastrais/informacoesCadastrais/uf').text
                                dados[:nr_recibo] = node.at_css('retornoConsultaInformacoesCadastrais/numeroRecibo').text
                                dados[:id] = node.at_css('retornoConsultaInformacoesCadastrais/id').text
                                dados[:tipo_ambiente] = args[0]

                                return dados, 'Sucesso', :success
                            else
                                dados[:cnpj] = cnpj_declarante
                                dados[:tipo_ambiente] = args[0]

                                return dados, "Código: #{node.at_css("dadosRegistroOcorrenciaEvento/ocorrencias/codigo").text}, #{node.at_css("dadosRegistroOcorrenciaEvento/ocorrencias/descricao").text}", :error
                            end
                        else
                            dados[:cnpj] = cnpj_declarante
                            dados[:tipo_ambiente] = args[0]

                            return dados, 'Problemas no servidor da Receita, não houve transmissão, aguarde alguns instantes!', :error
                        end
                    else
                        dados[:cnpj] = cnpj_declarante
                        dados[:tipo_ambiente] = args[0]

                        return dados, 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
                    end
                rescue Exception => e
                    return '', "#{e.message}", :error
                end
            when 'consultar_informacoes_movimento'
                begin
                    response = web_service_consulta(action, cnpj_declarante, *args)

                    if response.success?
                        node = Nokogiri::XML(response.xml)
                        node.remove_namespaces!
                        dados = Hash.new

                        # Verifica se existe o nó no XML de retorno
                        # ==========================================
                        if node.at_css('ConsultarInformacoesMovimentoResult')
                            if node.at_css('retornoConsultaInformacoesMovimento/status/cdRetorno').text.eql?('0')
                                dados[:cnpj] = cnpj_declarante
                                dados[:situacao_informacao] = args[0]
                                dados[:ano_mes_inicial] = args[1]
                                dados[:ano_mes_final] = args[2]
                                dados[:tipo_movimento] = args[3]
                                dados[:tipo_ni] = args[4]
                                dados[:ni] = args[5]
                                dados[:tipo_ambiente] = args[6]

                                count = 0

                                node.css('informacoesMovimento').each do |mov|
                                    count += 1

                                    m = Hash.new
                                    m[:tp_movimento] = mov.css('tipoMovimento').text
                                    m[:tpo_ni] = mov.css('tipoNI').text
                                    m[:ni] = mov.css('NI').text
                                    m[:ano_mes_caixa] = mov.css('anoMesCaixa').text
                                    m[:situacao] = mov.css('situacao').text
                                    m[:nr_recibo] = mov.css('numeroRecibo').text
                                    m[:id] = mov.css('id').text
                                    movimento = "movimento#{count}"
                                    dados.store(:"#{movimento}", m) # Anexa um novo hash no hash de dados.
                                end

                                return dados, 'Sucesso!', :success
                            else
                                dados[:cnpj] = cnpj_declarante
                                dados[:situacao_informacao] = args[0]
                                dados[:ano_mes_inicial] = args[1]
                                dados[:ano_mes_final] = args[2]
                                dados[:tipo_movimento] = args[3]
                                dados[:tipo_ni] = args[4]
                                dados[:ni] = args[5]
                                dados[:tipo_ambiente] = args[6]

                                return dados, "Código: #{node.at_css("dadosRegistroOcorrenciaEvento/ocorrencias/codigo").text}, #{node.at_css("dadosRegistroOcorrenciaEvento/ocorrencias/descricao").text}", :error
                            end
                        else
                            dados[:cnpj] = cnpj_declarante
                            dados[:situacao_informacao] = args[0]
                            dados[:ano_mes_inicial] = args[1]
                            dados[:ano_mes_final] = args[2]
                            dados[:tipo_movimento] = args[3]
                            dados[:tipo_ni] = args[4]
                            dados[:ni] = args[5]
                            dados[:tipo_ambiente] = args[6]
                            return dados, 'Problemas no servidor da Receita, não houve transmissão, aguarde alguns instantes!', :error
                        end
                    else
                        dados[:cnpj] = cnpj_declarante
                        dados[:situacao_informacao] = args[0]
                        dados[:ano_mes_inicial] = args[1]
                        dados[:ano_mes_final] = args[2]
                        dados[:tipo_movimento] = args[3]
                        dados[:tipo_ni] = args[4]
                        dados[:ni] = args[5]
                        dados[:tipo_ambiente] = args[6]
                        return dados, 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
                    end
                rescue Exception => e
                    return '', "#{e.message}", :error
                end
            when 'consultar_lista_eFinanceira'
                begin
                    response = web_service_consulta(action, cnpj_declarante, *args)

                    if response.success?
                        node = Nokogiri::XML(response.xml)
                        node.remove_namespaces!
                        dados = Hash.new

                        # Verifica se existe o nó no XML de retorno
                        # ==========================================
                        if node.at_css('ConsultarListaEFinanceiraResult')
                            if node.at_css('retornoConsultaListaEFinanceira/status/cdRetorno').text.eql?('0')
                                dados[:cnpj] = cnpj_declarante
                                dados[:situacao_financeira] = args[0]
                                dados[:data_inicio] = args[1]
                                dados[:data_fim] = args[2]
                                dados[:tipo_ambiente] = args[3]

                                count = 0

                                node.css('informacoesEFinanceira').each do |lista|
                                    count += 1

                                    l = Hash.new
                                    l[:data_inicio] = lista.css('dhInicial').text
                                    l[:data_fim] = lista.css('dhFinal').text
                                    l[:situacao_financeira] = lista.css('situacaoEFinanceira').text
                                    l[:nr_recibo_abertura] = lista.css('numeroReciboAbertura').text
                                    l[:id_abertura] = lista.css('idAbertura').text
                                    l[:nr_recibo_fechamento] = lista.css('numeroReciboFechamento').text
                                    l[:id_fechamento] = lista.css('id').text
                                    lista = "lista#{count}"
                                    dados.store(:"#{lista}", l) #Anexa um novo hash no hash de dados.
                                end

                                return dados, 'Sucesso!', :success
                                else
                                    dados[:cnpj] = cnpj_declarante
                                    dados[:situacao_financeira] = args[0]
                                    dados[:data_inicio] = args[1]
                                    dados[:data_fim] = args[2]
                                    dados[:tipo_ambiente] = args[3]

                                    return dados, "Código: #{node.at_css("dadosRegistroOcorrenciaEvento/ocorrencias/codigo").text}, #{node.at_css("dadosRegistroOcorrenciaEvento/ocorrencias/descricao").text}", :error
                                end
                            else
                                dados[:cnpj] = cnpj_declarante
                                dados[:situacao_financeira] = args[0]
                                dados[:data_inicio] = args[1]
                                dados[:data_fim] = args[2]
                                dados[:tipo_ambiente] = args[3]

                                return dados, 'Problemas no servidor da Receita, não houve transmissão, aguarde alguns instantes!', :error
                            end
                        else
                            dados[:cnpj] = cnpj_declarante
                            dados[:situacao_financeira] = args[0]
                            dados[:data_inicio] = args[1]
                            dados[:data_fim] = args[2]
                            dados[:tipo_ambiente] = args[3]

                            return dados, 'Não foi possível se comunicar com o servidor da Receita, aguarde alguns instantes!', :error
                        end
                rescue Exception => e
                    return '', "#{e.message}", :error
                end
            end
        else
            return '', "Código: MS0015, Deve ser utilizado certificado digital do tipo e-CNPJ ou e-PJ cujo CNPJ base seja o mesmo do contribuinte responsável pela informação, ou do tipo e-CPF ou e-PF cujo CPF pertença ao representante legal do contribuinte ou qualquer certificado que pertença a um procurador devidamente habilitado no sistema de Procuração Eletrônica da RFB.", :error
        end
    end

    def self.criptografia_lote_efinanceira(xmlDocLote, amb)
        if amb.eql?('producao')
            @@CERT_SERVER = CERT_SERVER_PROD
            @@ID_CERTIFICATE = ID_CERTIFICATE_PROD
        else
            @@CERT_SERVER = CERT_SERVER_HOMOLG
            @@ID_CERTIFICATE = ID_CERTIFICATE_HOMOLG
        end

        xml_lote_criptografado_base_64, key, iv = encripta_xml_com_chave_aes(xmlDocLote)
        chave_lote_criptografado_base_64 = encripta_chave_aes_com_chave_publica_certificado_servidor(key, iv, @@CERT_SERVER)

        builder = Nokogiri::XML::Builder.new do |xml|
            xml.eFinanceira(NAMESPACES_STANDARDS, 'xmlns'=>'http://www.eFinanceira.gov.br/schemas/envioLoteCriptografado/v1_2_0') {
                xml.loteCriptografado {
                    xml.id SecureRandom.uuid
                    xml.idCertificado @@ID_CERTIFICATE
                    xml.chave chave_lote_criptografado_base_64
                    xml.lote xml_lote_criptografado_base_64
                }
            }
        end

        doc = builder.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        xml_emcripty_encode = Base64.encode64(doc)

        return xml_emcripty_encode
    end

    def self.encripta_xml_com_chave_aes(xmlDocLote)
        xml_gzip = gzip(xmlDocLote,  level: Zlib::BEST_COMPRESSION, strategy: Zlib::DEFAULT_STRATEGY)

        cipher = OpenSSL::Cipher.new('AES-128-CBC')
        cipher.encrypt
        key = cipher.random_key
        iv = cipher.random_iv

        encrypted = cipher.update(xml_gzip) + cipher.final
        encrypted_data = Base64.encode64(encrypted)

        return encrypted_data, key, iv
    end

    def self.encripta_chave_aes_com_chave_publica_certificado_servidor(key, iv, thumbprintCertificado)
        chave_aes = key.concat(iv)
        file_data = File.read(thumbprintCertificado)
        cert = OpenSSL::X509::Certificate.new(file_data)
        rsa = OpenSSL::PKey::RSA.new cert.public_key
        chave_criptografada = rsa.public_encrypt(chave_aes)
        chave_criptografada_base_64 = Base64.encode64(chave_criptografada)

        return chave_criptografada_base_64
    end

    def self.gzip(string, level: nil, strategy: nil)
        sio = StringIO.new
        sio.binmode
        gz = Zlib::GzipWriter.new(sio, level, strategy)
        gz.write(string)
        gz.close

        return sio.string
    end

    ############################ MÉTODOS AUXILIARES PARA FINS ESPECÍFICOS ############################
    ###### Testa o schema com o xml
    def self.teste_xml_schema
        ###### Abre todas as dependências de outros schamas na pasta
        xsd = Nokogiri::XML::Schema(File.open('lib/efinanceiro/certificados/schemas/evtAberturaeFinanceira-v1_2_0.xsd'))
        doc = Nokogiri::XML(File.read('/home/samuel/Documentos/EFinanceiroPrev/xml_teste.xml'))
        xsd.validate(doc).each { |error| puts "Error: #{error}" }
    end

    ###### Método feito para poder dar o select abaixo com as quantidades por mês de movimentos.
    ###### select  ano_mes_caixa, count(*) as qtde from movimentos where ano_mes_caixa like '%2018%' and empresa_id = 1 group by ano_mes_caixa;
    def self.ano_mes_caixa
        Movimento.skip_callback(:save, :before, :checar_retorno)
        movimentos = Movimento.all

        movimentos.each do |m|
            dados = m.arquivo_origem.split(';')
            if dados[1].eql?('evtMovOpFin') and m.ano_mes_caixa.nil?
                m.ano_mes_caixa = m.created_at.year.to_s + m.created_at.month.to_s.rjust(2, '0')
                m.save
            else
                ####### IMPLEMENT  #######
            end
        end
        Movimento.set_callback(:save, :before, :checar_retorno)
    end
end
