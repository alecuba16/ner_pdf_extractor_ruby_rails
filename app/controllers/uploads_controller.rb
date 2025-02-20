class UploadsController < ApplicationController
  require 'pdf/reader'

  def index
    # Render the form for uploading a PDF
  end

  def upload
    # Check if a file was uploaded
    if params[:pdf].present? && params[:pdf].respond_to?(:path)
      pdf_path = params[:pdf].path
      begin
        # Extract text from the PDF
        text = extract_text_from_pdf(pdf_path)
        model = Mitie::NER.new(NerPdfExtractor::Application::MITIE_EN_MODEL)
        doc = model.doc(text)
        entities = doc.entities.map { |entity| { text: entity[:text], label: entity[:tag], score: entity[:score] } }
        @entities_grouped = entities.group_by { |entity| entity[:label] }
        # Log to inspect
        respond_to do |format|
          format.html { render :index, locals: { entities_grouped: @entities_grouped}, cache: false }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('entities-container', partial: 'entities', locals: { entities_grouped: @entities_grouped })
          end
        end
      rescue StandardError => e
        flash.now[:alert] = "Error processing the PDF: #{e.message}"
        render :index
      end
    else
      flash.now[:alert] = "Please upload a valid PDF file."
      render :index
    end
  end

  private

  def extract_text_from_pdf(pdf_path)
    text = ""
    PDF::Reader.open(pdf_path) do |reader|
      reader.pages.each do |page|
        text += page.text
      end
    end
    text
  end
end