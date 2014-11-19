require 'spec_helper'

#def createTarget
#  # create target, and fill out the form on /customers/new
#  Target.create(name: 'TestTarget', configuration: 'a=b')
#end


def createCustomer(customerName = "ExampleCustomer" )      
  # add and provision customer "ExampleCustomer with target = TestTarget"
  fillFormForNewCustomer(customerName)
  click_button 'Save', match: :first 
end

#def createCustomerDB(arguments = {})
def createCustomerDB(customerName = "nonProvisionedCust" )
	# creates a customer in the database without provisioning job

	# I have problems with FactoryGirls for adding database entries.
        # workaround: create customer by /customer/new click 'save' and remove the delayed job that is created 
        # the following works only, if delayed jobs is shut down, i.e. "rake jobs:work" is not allowed
        Delayed::Worker.delay_jobs = true
        createCustomer(customerName)

        # delete all delayed jobs of this customer
        @customer = Customer.where(name: customerName )
        @provisionings = Provisioning.where(customer: @customer)
        @provisionings.each do |provisioning|
          unless provisioning.delayedjob_id.nil?
            begin
              Delayed::Job.find(provisioning.delayedjob_id).destroy
            rescue
              # do nothing
            end
          end
        end

end

def createCustomerDB_not_working
  	FactoryGirl.create(:target)
        delta = Customer.count
p Customer.count.to_s + "<<<<<<<<<<<<<<<<<<<<< Customer.count before FactoryGirl.create"
        FactoryGirl.create(:customer)
p Customer.count.to_s + "<<<<<<<<<<<<<<<<<<<<< Customer.count after FactoryGirl.create"
	customer = Customer.find(1)
p customer.name + "<<<<<<<<<<<<<<<< customer.name"
        delta = Customer.count - delta
p delta.to_s + "<<<<<<<<<<<<<<<<<<<<< delta(Customer.count)"

end

def createCustomerDB_manual( arguments = {} )
	# default values
	arguments[:name] ||= "nonProvisionedCust"

        target = Target.new(name: "TestTarget", configuration: "a=b")
	target.save
	customer = Customer.new(name: "nonProvisionedCust", target_id: target.id)
        customer.save
end

def fillFormForNewCustomer(customerName = "ExampleCustomer" )
  if Target.where(name: 'TestTarget').count == 0
    Target.create(name: 'TestTarget', configuration: 'a=b')
  end
  visit new_customer_path # for refreshing after creating the target
  fill_in "Name",         with: customerName        
  select "TestTarget", :from => "customer[target_id]"
  
  # Note: select "TestTarget" selects the <option value=_whatever_>TestTarget</option> in the following select part of the HTML page:
  # Expected drop down in HTML page:
          #    <select id="customer_target_id" name="customer[target_id]">
          #    <option value="">Select a Target</option>
          #    <option value="2">TestTarget</option></select>
end

def destroyCustomer(customerName = "ExampleCustomer" )
  # for test: create the customer, if it does not exist:
  Delayed::Worker.delay_jobs = true
  createCustomer
  
  # de-provision the customer, if it exists on the target system
  # else delete the customer from the database
  customers = Customer.where(name: customerName)
  #p @customers[0].inspect
  unless customers[0].nil?
    Delayed::Worker.delay_jobs = false
    visit customer_path(customers[0])
    click_link "Destroy", match: :first
    Delayed::Worker.delay_jobs = true
  end
  
  # delete the customer from the database if it still exists
  customers = Customer.where(name: customerName)
  unless customers[0].nil?
    Delayed::Worker.delay_jobs = false
    visit customer_path(customers[0])
    click_link "Destroy", match: :first
    Delayed::Worker.delay_jobs = true
  end
end


describe "Customers" do
  #before { debugger }
  describe "index" do
    before { visit customers_path }   
    subject { page }
    
    it "should have the header 'Customers'" do
      expect(page).to have_selector('h2', text: 'Customers')
    end
    
    it "should have link to 'New Customer'" do     
      expect(page).to have_link( 'New Customer', href: new_customer_path )
    end
    
    its "link to 'New Customer' leads to correct page" do
      click_link "New Customer"
      expect(page).to have_selector('h2', text: 'New Customer')    
    end
    
  end # of describe "index" do
  
  describe "New Customer" do
    before { 
      # TODO: de-provision and delete customer, if it exists already
      destroyCustomer
      visit new_customer_path }
    
    it "should have the header 'New Customer'" do
      expect(page).to have_selector('h2', text: 'New Customer')
    end
    
    its "Cancel button in the left menue leads to the Customers index page" do
      click_link("Cancel", match: :first)
      expect(page).to have_selector('h2', text: 'Customers')    
    end
    
    its "Cancel button in the web form leads to the Customers index page" do
      #find html tag with class=index. Within this tag, find and click link 'Cancel' 
      first('.index').click_link('Cancel')
      expect(page).to have_selector('h2', text: 'Customers')    
    end
  end # of describe "New Customer" do
    
  describe "Create Customer" do
    before { visit new_customer_path }
    let(:submit) { "Save" }

    describe "with invalid information" do
      it "should not create a customer" do
        expect { click_button submit, match: :first }.not_to change(Customer, :count)
      end
      
      it "should not create a customer on second 'Save' button" do
        expect { first('.index').click_button submit, match: :first }.not_to change(Customer, :count)
      end
      
      describe "with duplicate name" do
        it "should not create a customer" do
          #createTarget
          createCustomer
          expect { createCustomer }.not_to change(Customer, :count)       
        end
      end
      
      # TODO: activate the test below and then implement https://www.railstutorial.org/book/_single-page#sec-uniqueness_validation 
      #describe "with case-insensitive duplicate name" do
      #  it "should not create a customer" do
      #    #createTarget
      #    customerName = "CCCCust"
      #    createCustomer customerName
      #    expect { createCustomer customerName.to_lower }.not_to change(Customer, :count)       
      #  end
      #end
    end
    
    
    describe "with valid information" do
      # does not work yet (is just ignored):
      #let(:target) { FactoryGirls.create(:target) }
      before do
        #createTarget
        fillFormForNewCustomer
      end

      ############## FactoryGirl not yet functional ###########
      it "has a valid factory" do
        FactoryGirl.create(:target).should be_valid
        FactoryGirl.create(:customer).should be_valid
      end

      it "should add a customer to the database (FactoryGirlTest)" do
        FactoryGirl.create(:target)
        delta = Customer.count
        	p Customer.count.to_s + "<<<<<<<<<<<<<<<<<<<<<"
        #FactoryGirl.attributes_for(:customer, name: "dhgkshk")
      	FactoryGirl.create(:customer)
      	customer = Customer.find(1)
              	p customer.name + "<<<<<<<<<<<<<<<< customer.name"
      	delta = Customer.count - delta
              	p delta.to_s + "<<<<<<<<<<<<<<<<<<<<< delta"
      	expect(delta).to eq(1)
              #expect(FactoryGirl.create(:customer)).to change(Customer, :count).by(1)
              #expect(FactoryGirl.build(:customer)).to change(Customer, :count).by(1)
      	p Customer.count.to_s + "<<<<<<<<<<<<<<<<<<<<<"
      end
      
      it "should create a customer (1st 'Save' button)" do
        expect { click_button submit, match: :first }.to change(Customer, :count).by(1)       
      end
      
      it "should create a customer (2nd 'Save' button)" do
        expect { first('.index').click_button submit, match: :first }.to change(Customer, :count).by(1)
      end
      
      it "should create a customer with status 'provisioning success'" do
        # synchronous operation, so we will get deterministic test results:         
        Delayed::Worker.delay_jobs = false
        
        # TODO: should redirect to customer_path(created_customer_id)
        click_button submit, match: :first
        # for debugging:
        #p page.html.gsub(/[\n\t]/, '')
        
        # redirected page should show provisioning success
        expect(page.html.gsub(/[\n\t]/, '')).to match(/provisioning success/) #have_selector('h2', text: 'Customers')
        
        # /customers/<id> should show provisioning success
        customers = Customer.where(name: "ExampleCustomer" )
        visit customer_path(customers[0])
        # for debugging:
        #p page.html.gsub(/[\n\t]/, '')
        page.html.gsub(/[\n\t]/, '').should match(/provisioning success/)
               
      end
      
      
      it "should create a provisioning task" do
        expect { click_button submit, match: :first }.to change(Provisioning, :count).by(1)         
      end
      
      it "should create a provisioning task (2nd 'Save' button)" do
        expect { first('.index').click_button submit, match: :first }.to change(Provisioning, :count).by(1)         
      end
      
      it "should create a provisioning task with action='action=Add Customer' and 'customerName=ExampleCustomer'" do
        click_button submit, match: :first
        createdProvisioningTask = Provisioning.find(Provisioning.last)
        createdProvisioningTask.action.should match(/action=Add Customer/)
        createdProvisioningTask.action.should match(/customerName=ExampleCustomer/)
      end
      
      it "should create a provisioning task that finishes successfully or throws an Error 'Customer exists already'" do
        Delayed::Worker.delay_jobs = false
        click_button submit, match: :first
        createdProvisioningTask = Provisioning.find(Provisioning.last)
        begin
          createdProvisioningTask.status.should match(/finished successfully/)
        rescue
          createdProvisioningTask.status.should match(/Customer exists already/)          
        end
        
      end  
      
    end # of describe "with valid information" do
    
  end # of describe "Create Customer" do
    
  describe "Destroy Customer" do
    describe "De-Provision Customer" do
      before {
        # synchronous hancdling to make test results more deterministic
        Delayed::Worker.delay_jobs = false
        #createTarget
        createCustomer
        Delayed::Worker.delay_jobs = true
        
        customers = Customer.where(name: "ExampleCustomer" )            
        visit customer_path(customers[0])
        #p page.html.gsub(/[\n\t]/, '')
       
      }
         
      let(:submit) { "Delete Customer" }
      let(:submit2) { "Destroy" }
      
      # TODO: add destroy use cases
        # De-Provisioning of customer
        # Deletion of customer from database
      it "should delete a customer with status 'deletion success'" do
        # synchronous operation, so we will get deterministic test results:         
        Delayed::Worker.delay_jobs = false
        
        click_link submit, match: :first
        expect(page.html.gsub(/[\n\t]/, '')).to match(/deletion success/) #have_selector('h2', text: 'Customers')
        
        # /customers/<id> should show provisioning success
        customers = Customer.where(name: "ExampleCustomer" )
        p customers
        visit customer_path(customers[0])
        # for debugging:
        #p page.html.gsub(/[\n\t]/, '')
        page.html.gsub(/[\n\t]/, '').should match(/deletion success/)      
      end
    end # of describe "De-Provision Customer" do
    
    describe "Delete Customer from database using manual database seed" do
      before {
        createCustomerDB_manual(name: "nonProvisionedCust")
        customers = Customer.where(name: "nonProvisionedCust" )
                #p customers.inspect
        visit customer_path(customers[0])
                #p page.html.gsub(/[\n\t]/, '')
      }


      let(:submit) { "Delete Customer" }
      let(:submit2) { "Destroy" }

      it "should remove a customer from the database, if not found on the target system" do
        Delayed::Worker.delay_jobs = false
	
	expect(page).to have_link("Delete Customer")

        delta = Customer.count
		#p Customer.count.to_s + "<<<<<<<<<<<<<<<<<<<<< Customer.count before click"
        click_link "Delete Customer"
        	# replacing by following line causes error "Unable to find link :submit" (why?)
        	#click_link :submit
			#p page.html.gsub(/[\n\t]/, '')
		# following line causes error: 
        	#expect(click_link "Delete Customer").to change(Customer, :count).by(-1)
        delta = Customer.count - delta
        expect(delta).to eq(-1)
		#p Customer.count.to_s + "<<<<<<<<<<<<<<<<<<<<< Customer.count after click"
      end
    end


    describe "Delete Customer from database" do
      
      before {
        # setting Delayed::Worker.delay_jobs = true causes the provisioning task not to be executed (assumption: rake jobs:work task is not started for the test enviroment)
        #Delayed::Worker.delay_jobs = true
#        Delayed::Worker.delay_jobs = false
#        #createTarget
#        createCustomer("nonProvisionedCust")
#        customers = Customer.where(name: "nonProvisionedCust" )
#        visit customer_path(customers[0])
#
#        p page.html.gsub(/[\n\t]/, '')       
	
#	# I have problems with FactoryGirls for adding database entries.
#	# workaround: create customer by click and remove the delayed job this creates
#        # the following works only, if delayed jobs is not up and running; i.e. no rake jobs:work must be up and running
#	Delayed::Worker.delay_jobs = true
#	createCustomer("nonProvisionedCust")
#
#        # delete all delayed jobs:
#    	@customer = Customer.where(name: "nonProvisionedCust")
#		p "-------------------------- " + @customer.inspect
#    	@provisionings = Provisioning.where(customer: @customer)
#    	@provisionings.each do |provisioning|
#      	  unless provisioning.delayedjob_id.nil?
#            begin
#              #activeProvisioningJob = Delayed::Job.find(provisioning.delayedjob_id)
#              Delayed::Job.find(provisioning.delayedjob_id).destroy
#            rescue
#              # keep: activeProvisioningJob = nil
#            end
#          end
#        end
	
	createCustomerDB( "nonProvisionedCust" )
	#createCustomerDB_not_working
        customers = Customer.where(name: "nonProvisionedCust" )
        visit customer_path(customers[0])
	
	# debug:
        p page.html.gsub(/[\n\t]/, '')
	
       }
         
      let(:submit) { "Delete Customer" }
      let(:submit2) { "Destroy" }
      
      it "(working) should remove a customer from the database, if not found on the target system" do
        expect { click_link submit, match: :first }.to change(Customer, :count).by(-1)
      end
      
    end # of describe "Delete Customer from database" do
  
  end # of describe "Destroy Customer" do
    
end # describe "Customers" do
