package dff_tb_pkg;
    class dff_item;
        rand bit d;
        int unsigned id;

        function new(int unsigned id = 0);
            this.id = id;
        endfunction
    endclass

    class dff_generator;
        mailbox #(dff_item) gen2drv;

        function new(mailbox #(dff_item) gen2drv);
            this.gen2drv = gen2drv;
        endfunction

        task run(int unsigned count);
            dff_item item;
            for (int unsigned i = 0; i < count; i++) begin
                item = new(i);
                if (!item.randomize())
                    $fatal(1, "Randomization failed for item %0d", i);
                gen2drv.put(item);
            end
        endtask
    endclass

    class dff_driver;
        virtual dff_if vif;
        mailbox #(dff_item) gen2drv;

        function new(virtual dff_if vif, mailbox #(dff_item) gen2drv);
            this.vif = vif;
            this.gen2drv = gen2drv;
        endfunction

        task run(int unsigned count);
            dff_item item;
            vif.d = 1'b0;
            repeat (count) begin
                gen2drv.get(item);
                @(negedge vif.clk);
                vif.d <= item.d;
                $display("[%0t] DRIVER   item=%0d d=%0b", $time, item.id, item.d);
            end
        endtask
    endclass

    class dff_observation;
        logic d;
        logic q;
        int unsigned cycle;
    endclass

    class dff_monitor;
        virtual dff_if vif;
        mailbox #(dff_observation) mon2scb;

        function new(virtual dff_if vif, mailbox #(dff_observation) mon2scb);
            this.vif = vif;
            this.mon2scb = mon2scb;
        endfunction

        task run(int unsigned cycles);
            dff_observation obs;
            for (int unsigned i = 0; i < cycles; i++) begin
                @(posedge vif.clk);
                #1step;
                obs = new();
                obs.d = vif.d;
                obs.q = vif.q;
                obs.cycle = i;
                mon2scb.put(obs);
                $display("[%0t] MONITOR  cycle=%0d d=%0b q=%0b",
                         $time, obs.cycle, obs.d, obs.q);
            end
        endtask
    endclass

    class dff_scoreboard;
        mailbox #(dff_observation) mon2scb;

        function new(mailbox #(dff_observation) mon2scb);
            this.mon2scb = mon2scb;
        endfunction

        task run(int unsigned cycles);
            dff_observation obs;
            logic previous_d;
            bit have_previous;
            previous_d = 1'bx;
            have_previous = 0;

            repeat (cycles) begin
                mon2scb.get(obs);
                if (have_previous && obs.q !== previous_d)
                    $error("CHECK FAILED cycle=%0d: q=%0b expected previous d=%0b",
                           obs.cycle, obs.q, previous_d);
                else if (have_previous)
                    $display("[%0t] SCOREBOARD PASS cycle=%0d", $time, obs.cycle);

                previous_d = obs.d;
                have_previous = 1;
            end
        endtask
    endclass
endpackage
