require 'spec_helper'
require 'ignorance'

describe Ignorance do

  describe "class methods (e.g. Ingorance.guard...)" do
    subject { Ignorance }
    it { should respond_to :advise, :guard, :negotiate, :guarantee! }
  end

  describe "when included" do
    before do
      class TestIncluder
        include Ignorance
      end
    end
    subject { TestIncluder.new }

    it { should respond_to :advise_ignorance, :guard_ignorance, :negotiate_ignorance, :guarantee_ignorance! }
  end

  context "Git", :fakefs do
    before            { mk_repo_dir  }
    let(:ignore_file) { '.gitignore' }
    let(:repo_dir)    { '.git'       }
    let(:token)       { "foo.rb"     }

    describe "::advise", :capture_io do

      context "token is already in ignore file" do
        before { ignorefile_write "#{token}\n" }

        it "does not warn" do
          expect( stderr_from { Ignorance.advise token } ).to be_empty
        end
      end

      context "token is NOT in ignore file" do
        before { ignorefile_write "something-else.txt\n" }

        it "prints warn (STDERR)" do
          expect( stderr_from { Ignorance.advise token } ).to match /WARNING:.*add "#{token}" to .*#{ignore_file}/
        end
      end
    end

    describe "::guard" do
      context "token is already in ignore file" do
        before { ignorefile_write "#{token}\n" }

        specify "no error is raised" do
          expect { Ignorance.guard token }.to_not raise_error
        end
      end

      context "token is NOT in ignore file" do
        before { ignorefile_write "something-else.txt\n" }

        it "raises an error" do
          expect { Ignorance.guard token }.to raise_error Ignorance::IgnorefileError, /add "#{token}" to .*#{ignore_file}/
        end
      end
    end

    describe "::negotiate", :capture_io do

      context "token is already in ignore file" do
        before { ignorefile_write "#{token}\n" }

        it "does nothing" do
          expect( stdout_from { Ignorance.negotiate token } ).to be_empty
        end
      end

      context "token is NOT in ignore file" do
        before { ignorefile_write "stuff.txt\n" }

        context "user agrees (y)" do
          specify do
            expect( user_types("y") { Ignorance.negotiate token } ).to match /added "#{token}"/i
          end
        end

        context "user disagrees (n)" do
          specify do
            expect( user_types("n") { Ignorance.negotiate token } ).to match /WARNING:.*add "#{token}" to .*#{ignore_file}/
          end
        end
      end
    end

    describe "::guarantee!" do
      context "token is already in ignore file" do
        before { ignorefile_write "#{token}\n" }

        it "does not change the ignore file" do
          Ignorance.guarantee! token, "a comment"
          ignorefile_contents.should == "#{token}\n"
        end
      end

      context "token is NOT in ignore file" do
        before { ignorefile_write "stuff.txt\n" }

        it "adds to the ignore file" do
          Ignorance.guarantee! token, "a comment"
          ignorefile_contents.should == "stuff.txt\n\n# a comment\n#{token}\n"
        end
      end
    end

  end

end
